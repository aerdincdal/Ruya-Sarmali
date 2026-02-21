import Foundation

struct DreamBackendCoordinator {
    enum BackendError: LocalizedError {
        case missingServices
        case interpretationUnavailable
        case videoUnavailable
        case authenticationRequired

        var errorDescription: String? {
            switch self {
            case .missingServices: return "API anahtarları ayarlanmadı."
            case .interpretationUnavailable: return "Rüya yorumu alınamadı."
            case .videoUnavailable: return "Video üretimi başarısız oldu."
            case .authenticationRequired: return "Lütfen giriş yapın."
            }
        }
    }

    struct Result {
        let interpretation: DreamInterpretation
        let remoteVideoURL: URL?
        let localFileURL: URL
        let lumaGenerationId: String?
    }

    let interpreter: DreamInterpretationService?
    let lumaService: LumaAIService?
    let supabase: SupabaseService?
    let fallbackSynthesizer: DreamVideoSynthesizer
    let sqliteStore: SQLiteDreamStore?

    init(interpreter: DreamInterpretationService?, lumaService: LumaAIService?, supabase: SupabaseService?, sqliteStore: SQLiteDreamStore?, fallbackSynthesizer: DreamVideoSynthesizer = DreamVideoSynthesizer()) {
        self.interpreter = interpreter
        self.lumaService = lumaService
        self.supabase = supabase
        self.fallbackSynthesizer = fallbackSynthesizer
        self.sqliteStore = sqliteStore
    }

    func interpret(prompt: String) async throws -> DreamInterpretation {
        if let interpreter {
            return try await interpreter.interpret(prompt: prompt)
        }
        throw BackendError.missingServices
    }

    /// Generate video assets with optional progress callback
    /// Note: On simulator, skips Luma API to save credits and uses local fallback
    func generateAssets(
        prompt: String,
        interpretation: DreamInterpretation,
        resolution: String = "720p",
        duration: String = "5s",
        onProgress: @escaping (LumaProgressUpdate) -> Void = { _ in }
    ) async throws -> Result {
        // Skip Luma API on simulator to save credits during development
        #if targetEnvironment(simulator)
        print("🧪 SIMULATOR: Skipping Luma API to save credits. Using local fallback video.")
        let localURL = try await fallbackSynthesizer.renderVideo(for: interpretation.summary)
        return Result(interpretation: interpretation, remoteVideoURL: nil, localFileURL: localURL, lumaGenerationId: nil)
        #else
        // Real device - use Luma API
        if let lumaService {
            do {
                let remoteURL = try await lumaService.generateVideo(
                    prompt: prompt,
                    mood: interpretation.celestialAdvice,
                    resolution: resolution,
                    duration: duration,
                    onProgress: onProgress
                )
                let downloadedURL = try await downloadRemoteVideo(from: remoteURL)
                let generationId = remoteURL.lastPathComponent
                return Result(
                    interpretation: interpretation,
                    remoteVideoURL: remoteURL,
                    localFileURL: downloadedURL,
                    lumaGenerationId: generationId
                )
            } catch {
                print("Luma AI üretimi başarısız: \(error.localizedDescription). Lokal sentetik video kullanılacak.")
            }
        }

        let localURL = try await fallbackSynthesizer.renderVideo(for: interpretation.summary)
        return Result(interpretation: interpretation, remoteVideoURL: nil, localFileURL: localURL, lumaGenerationId: nil)
        #endif
    }

    func logDream(prompt: String, interpretation: DreamInterpretation, remoteVideoURL: URL?, localFilename: String? = nil, lumaGenerationId: String? = nil) async {
        // Log to Supabase (with user binding via auth service)
        await supabase?.logDream(prompt: prompt, interpretation: interpretation.summary, remoteVideoURL: remoteVideoURL)
        
        // Also log to local SQLite for offline access
        sqliteStore?.add(prompt: prompt, interpretation: interpretation.summary, remoteURL: remoteVideoURL)
    }

    private func downloadRemoteVideo(from remoteURL: URL) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw NSError(domain: "LumaAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Video indirilemedi"])
        }

        let downloadedPath = FileManager.default.temporaryDirectory.appendingPathComponent("luma_\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: downloadedPath.path) {
            try FileManager.default.removeItem(at: downloadedPath)
        }
        try FileManager.default.moveItem(at: tempURL, to: downloadedPath)
        
        // Add watermark to video
        print("📝 Adding watermark to video...")
        do {
            let watermarkedURL = try await VideoWatermarkProcessor.addWatermark(to: downloadedPath)
            // Clean up original
            try? FileManager.default.removeItem(at: downloadedPath)
            return watermarkedURL
        } catch {
            print("⚠️ Watermark ekleme başarısız: \(error.localizedDescription). Orijinal video kullanılıyor.")
            return downloadedPath
        }
    }
}
