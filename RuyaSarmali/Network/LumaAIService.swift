import Foundation

/// Progress update during Luma video generation
struct LumaProgressUpdate {
    let attempt: Int
    let maxAttempts: Int
    let state: String
    let estimatedSecondsRemaining: Int
    
    var progressPercentage: Double {
        return min(Double(attempt) / Double(maxAttempts) * 0.9, 0.95) // Cap at 95% until complete
    }
    
    var statusMessage: String {
        let minutes = estimatedSecondsRemaining / 60
        let seconds = estimatedSecondsRemaining % 60
        
        switch state {
        case "queued":
            return "Sıraya alındı... ⏳"
        case "dreaming":
            if minutes > 0 {
                return "Video üretiliyor... ~\(minutes) dk \(seconds) sn 🎬"
            } else {
                return "Video üretiliyor... ~\(seconds) sn 🎬"
            }
        case "processing":
            return "İşleniyor... 🔄"
        case "completed":
            return "Tamamlandı! ✅"
        case "failed":
            return "Başarısız ❌"
        default:
            return "Hazırlanıyor... ⏳"
        }
    }
}

struct LumaAIService {
    struct GenerationResponse: Decodable {
        struct Assets: Decodable {
            let video: URL?
        }

        let id: String
        let state: String
        let failure_reason: String?
        let assets: Assets?
    }

    enum GenerationState: String {
        case completed
        case failed
        case processing
        case queued
        case dreaming
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL: URL

    init?(apiKey: String?, baseURL: URL = URL(string: "https://api.lumalabs.ai/dream-machine/v1")!, session: URLSession = .shared) {
        guard let apiKey, !apiKey.isEmpty else { return nil }
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    /// Generate optimized dream video with ray-flash-2 (3x faster, 3x cheaper)
    /// - Parameters:
    ///   - prompt: User's dream description
    ///   - mood: Astrological/celestial mood guidance
    ///   - resolution: 540p, 720p, 1080p (default: 720p for cost optimization)
    ///   - duration: "5s" or "9s" (default: 5s for cost optimization)
    ///   - onProgress: Callback for progress updates
    func generateVideo(
        prompt: String,
        mood: String,
        resolution: String = "720p",
        duration: String = "5s",
        onProgress: ((LumaProgressUpdate) -> Void)? = nil
    ) async throws -> URL {
        struct Payload: Encodable {
            let prompt: String
            let model: String
            let aspect_ratio: String
            let resolution: String
            let duration: String
            let loop: Bool
        }

        // Optimized prompt - concise for faster processing and lower token cost
        let cinematicPrompt = """
        Dreamlike cinematic video: \(prompt). \
        Style: ethereal slow-motion, mystical lighting, fantasy surrealism. \
        Mood: \(mood)
        """
        
        let payload = Payload(
            prompt: cinematicPrompt,
            model: "ray-flash-2",     // 3x faster, 3x cheaper than ray-2
            aspect_ratio: "9:16",     // Mobile-optimized vertical
            resolution: resolution,    // 720p default for cost optimization
            duration: duration,        // 5s default for cost optimization
            loop: false               // No loop for story continuity
        )
        let createURL = baseURL.appendingPathComponent("generations")
        var request = URLRequest(url: createURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        print("🎬 LumaAI: Sending request to \(createURL)")
        let (data, response) = try await session.data(for: request)
        print("🎬 LumaAI: Response received - \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        
        if let responseStr = String(data: data, encoding: .utf8) {
            print("🎬 LumaAI: Response body - \(responseStr.prefix(500))")
        }
        
        guard let creation = try validate(response: response, data: data) else {
            throw NSError(domain: "LumaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Boş içerik alındı"])
        }

        print("🎬 LumaAI: Generation created with ID: \(creation.id)")
        return try await pollGeneration(id: creation.id, onProgress: onProgress)
    }

    private func pollGeneration(id: String, onProgress: ((LumaProgressUpdate) -> Void)?) async throws -> URL {
        let statusURL = baseURL.appendingPathComponent("generations/\(id)")
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        print("🎬 LumaAI: Starting poll for generation \(id)")
        
        let maxAttempts = 120  // 120 * 3 seconds = 6 minutes
        let pollInterval: UInt64 = 3_000_000_000 // 3 seconds in nanoseconds
        
        for attempt in 0..<maxAttempts {
            let (data, response) = try await session.data(for: request)
            guard let generation = try validate(response: response, data: data) else {
                throw NSError(domain: "LumaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Luma API boş yanıt gönderdi"])
            }

            // Calculate realistic progress based on ray-flash-2 (~10-30 seconds typical)
            let estimatedTotalAttempts = 10 // ~30 seconds typical for ray-flash-2
            let remainingAttempts = max(estimatedTotalAttempts - attempt, 1)
            let estimatedSecondsRemaining = remainingAttempts * 3
            
            let progressUpdate = LumaProgressUpdate(
                attempt: attempt + 1,
                maxAttempts: maxAttempts,
                state: generation.state,
                estimatedSecondsRemaining: estimatedSecondsRemaining
            )
            
            // Call progress callback on main thread
            await MainActor.run {
                onProgress?(progressUpdate)
            }
            
            print("🎬 LumaAI: Poll attempt \(attempt + 1)/\(maxAttempts) - State: \(generation.state)")
            
            switch GenerationState(rawValue: generation.state) {
            case .completed:
                if let url = generation.assets?.video {
                    print("🎬 LumaAI: ✅ Video ready at \(url)")
                    return url
                } else {
                    throw NSError(domain: "LumaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video URL bulunamadı"])
                }
            case .failed:
                print("🎬 LumaAI: ❌ Generation failed - \(generation.failure_reason ?? "unknown")")
                throw NSError(domain: "LumaAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: generation.failure_reason ?? "Luma AI üretimi başarısız"])
            case .processing, .queued, .dreaming, .none:
                try await Task.sleep(nanoseconds: pollInterval)
            }
        }
        print("🎬 LumaAI: ⏱️ Timeout after \(maxAttempts) attempts (6 minutes)")
        throw NSError(domain: "LumaAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Luma AI zaman aşımı - Video üretimi 6 dakikadan uzun sürdü"])
    }

    private func validate(response: URLResponse, data: Data) throws -> GenerationResponse? {
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? ""
            print("🎬 LumaAI: ❌ HTTP Error \((response as? HTTPURLResponse)?.statusCode ?? -1): \(message)")
            throw NSError(domain: "LumaAIService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Luma AI hatası: \(message)"])
        }
        return try JSONDecoder().decode(GenerationResponse.self, from: data)
    }
}
