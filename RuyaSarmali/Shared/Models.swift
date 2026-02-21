import SwiftUI
import UniformTypeIdentifiers

struct DreamVideo: Identifiable, Codable, Equatable {
    let id: UUID
    var prompt: String
    var createdAt: Date
    var fileName: String
    var palette: [ColorPayload]
    var interpretation: String?
    var remoteVideoURL: String?

    var previewGradient: LinearGradient {
        LinearGradient(colors: palette.prefix(2).map { $0.color } + [Color(hex: 0x241942)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct ColorPayload: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }

    static func random() -> ColorPayload {
        ColorPayload(red: Double.random(in: 0.2...0.9), green: Double.random(in: 0.2...0.9), blue: Double.random(in: 0.4...0.95))
    }
}

@MainActor
final class DreamRepository: ObservableObject {
    @Published private(set) var videos: [DreamVideo] = []

    private let metadataURL: URL
    private let fileManager = FileManager.default
    private let storageDirectory: URL

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        storageDirectory = documents.appendingPathComponent("DreamVault", isDirectory: true)
        metadataURL = storageDirectory.appendingPathComponent("dreams.json")
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        Task { await loadInitialData() }
    }

    func url(for video: DreamVideo) -> URL {
        storageDirectory.appendingPathComponent(video.fileName)
    }

    func persistVideo(from sourceURL: URL, prompt: String, interpretation: String? = nil, remoteURL: URL? = nil) async throws -> DreamVideo {
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        let fileName = sourceURL.lastPathComponent
        let destination = storageDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: sourceURL, to: destination)
        let video = DreamVideo(
            id: UUID(),
            prompt: prompt,
            createdAt: Date(),
            fileName: fileName,
            palette: [ColorPayload.random(), ColorPayload.random(), ColorPayload.random()],
            interpretation: interpretation,
            remoteVideoURL: remoteURL?.absoluteString
        )
        videos.insert(video, at: 0)
        try await persistMetadata()
        return video
    }

    func persistVideo(fromRemoteURL remoteURL: URL, prompt: String, interpretation: String?) async throws -> DreamVideo {
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        return try await persistVideo(from: tempURL, prompt: prompt, interpretation: interpretation, remoteURL: remoteURL)
    }

    func delete(_ video: DreamVideo) {
        videos.removeAll { $0.id == video.id }
        let url = storageDirectory.appendingPathComponent(video.fileName)
        try? fileManager.removeItem(at: url)
        Task { try? await persistMetadata() }
    }

    private func loadInitialData() async {
        guard fileManager.fileExists(atPath: metadataURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoded = try JSONDecoder().decode([DreamVideo].self, from: data)
            self.videos = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Failed to load metadata: \(error)")
        }
    }

    private func persistMetadata() async throws {
        let data = try JSONEncoder().encode(videos)
        try data.write(to: metadataURL, options: .atomic)
    }
}
