import SwiftUI
import Photos

@MainActor
final class DreamGenerationViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var progressMessage: String = ""
    @Published var currentVideo: DreamVideo?
    @Published var errorMessage: String?
    @Published var astroInterpretation: DreamInterpretation?
    @Published var isInterpreting: Bool = false
    @Published var showInterpretationSheet: Bool = false

    private let repository: DreamRepository
    private let backend: DreamBackendCoordinator
    private let creditManager: CreditManager
    private var pendingCreditCost: Int = 0

    init(repository: DreamRepository, backend: DreamBackendCoordinator, creditManager: CreditManager) {
        self.repository = repository
        self.backend = backend
        self.creditManager = creditManager
    }

    func generateVideo() {
        guard prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 else {
            errorMessage = "Lütfen rüyanı biraz daha detaylandır."
            return
        }

        let cost = creditManager.creditCostPerVideo
        guard creditManager.consumeCredit(cost: cost) else {
            errorMessage = "Kredi veya demo hakkın yeterli değil."
            return
        }
        pendingCreditCost = cost

        isGenerating = true
        progress = 0
        progressMessage = "Hazırlanıyor..."
        errorMessage = nil

        Task {
            do {
                let interpretation = try await backend.interpret(prompt: prompt)
                astroInterpretation = interpretation
                
                // Use real progress callback from Luma API
                let result = try await backend.generateAssets(
                    prompt: prompt,
                    interpretation: interpretation,
                    resolution: "720p",
                    duration: "5s"
                ) { [weak self] update in
                    guard let self else { return }
                    self.progress = update.progressPercentage
                    self.progressMessage = update.statusMessage
                }

                var stored: DreamVideo
                do {
                    stored = try await repository.persistVideo(from: result.localFileURL, prompt: prompt, interpretation: interpretation.combined, remoteURL: result.remoteVideoURL)
                } catch {
                    throw DreamBackendCoordinator.BackendError.videoUnavailable
                }

                currentVideo = stored
                progress = 1
                await backend.logDream(prompt: prompt, interpretation: interpretation, remoteVideoURL: result.remoteVideoURL)
                pendingCreditCost = 0
            } catch {
                errorMessage = "Üretim başarısız: \(error.localizedDescription)"
                creditManager.refundCredits(pendingCreditCost)
                pendingCreditCost = 0
            }
            isGenerating = false
            progressMessage = ""
        }
    }

    func requestAstroInterpretation() {
        guard prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 else {
            errorMessage = "Önce rüyanı biraz daha detaylandır."
            return
        }
        isInterpreting = true
        errorMessage = nil
        Task {
            defer { isInterpreting = false }
            do {
                let interpretation = try await backend.interpret(prompt: prompt)
                astroInterpretation = interpretation
                showInterpretationSheet = true
            } catch {
                errorMessage = "Yorum alınamadı: \(error.localizedDescription)"
            }
        }
    }

    func discardCurrentVideo() {
        currentVideo = nil
    }

    func saveToPhotos() async throws {
        guard let currentVideo else { return }
        try await PhotoLibraryWriter.saveVideo(at: repository.url(for: currentVideo))
    }
}

struct PhotoLibraryWriter {
    static func saveVideo(at url: URL) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized ||
                PHPhotoLibrary.authorizationStatus(for: .addOnly) == .limited else {
            throw NSError(domain: "RuyaSarmali", code: 401, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf arşivine erişim gerekli"])
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}
