import Foundation

struct SupabaseConfig {
    let url: URL
    let anonKey: String
    let tableName: String

    init?(baseURLString: String?, anonKey: String?, tableName: String?) {
        guard let baseURLString,
              let url = URL(string: baseURLString),
              let anonKey,
              let tableName,
              !anonKey.isEmpty,
              !tableName.isEmpty else { return nil }
        self.url = url
        self.anonKey = anonKey
        self.tableName = tableName
    }
}

// MARK: - Dream Record Model

struct DreamRecord: Codable, Identifiable {
    let id: String?
    let user_id: String
    let prompt: String
    let interpretation: String?
    let celestial_advice: String?
    let luma_generation_id: String?
    let video_url: String?
    let local_filename: String?
    let resolution: String?
    let duration: String?
    let is_shared: Bool?
    let created_at: String?
    let updated_at: String?
}

// MARK: - SupabaseService

@MainActor
final class SupabaseService: ObservableObject {
    private let config: SupabaseConfig
    private let session: URLSession
    private weak var authService: SupabaseAuthService?
    
    @Published private(set) var dreams: [DreamRecord] = []
    @Published private(set) var isLoading: Bool = false

    init?(config: SupabaseConfig?, authService: SupabaseAuthService? = nil, session: URLSession = .shared) {
        guard let config else { return nil }
        self.config = config
        self.authService = authService
        self.session = session
    }
    
    func setAuthService(_ authService: SupabaseAuthService) {
        self.authService = authService
    }

    // MARK: - Create Dream
    
    func saveDream(
        userId: String,
        prompt: String,
        interpretation: String?,
        celestialAdvice: String?,
        lumaGenerationId: String?,
        videoURL: URL?,
        localFilename: String?,
        resolution: String = "1080p",
        duration: String = "9s"
    ) async throws -> DreamRecord {
        let record = DreamRecord(
            id: nil,
            user_id: userId,
            prompt: prompt,
            interpretation: interpretation,
            celestial_advice: celestialAdvice,
            luma_generation_id: lumaGenerationId,
            video_url: videoURL?.absoluteString,
            local_filename: localFilename,
            resolution: resolution,
            duration: duration,
            is_shared: false,
            created_at: nil,
            updated_at: nil
        )
        
        guard let requestURL = URL(string: "/rest/v1/dreams", relativeTo: config.url) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        // Add auth token if available
        if let token = try? await authService?.getValidAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(record)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
            throw NSError(domain: "SupabaseService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let savedRecords = try JSONDecoder().decode([DreamRecord].self, from: data)
        guard let savedRecord = savedRecords.first else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kayıt döndürülemedi"])
        }
        
        dreams.insert(savedRecord, at: 0)
        return savedRecord
    }
    
    // MARK: - Fetch Dreams
    
    func fetchDreams(userId: String, limit: Int = 50) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard var urlComponents = URLComponents(url: config.url.appendingPathComponent("rest/v1/dreams"), resolvingAgainstBaseURL: true) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let requestURL = urlComponents.url else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(config.anonKey, forHTTPHeaderField: "apikey")
        
        if let token = try? await authService?.getValidAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw NSError(domain: "SupabaseService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Rüyalar yüklenemedi"])
        }
        
        dreams = try JSONDecoder().decode([DreamRecord].self, from: data)
    }
    
    // MARK: - Delete Dream
    
    func deleteDream(dreamId: String) async throws {
        guard var urlComponents = URLComponents(url: config.url.appendingPathComponent("rest/v1/dreams"), resolvingAgainstBaseURL: true) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(dreamId)")
        ]
        
        guard let requestURL = urlComponents.url else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        request.addValue(config.anonKey, forHTTPHeaderField: "apikey")
        
        if let token = try? await authService?.getValidAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw NSError(domain: "SupabaseService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Rüya silinemedi"])
        }
        
        dreams.removeAll { $0.id == dreamId }
    }
    
    // MARK: - Legacy Log Method (backward compatibility)
    
    func logDream(prompt: String, interpretation: String, remoteVideoURL: URL?) async {
        guard let userId = authService?.currentUser?.id else {
            print("SupabaseService: No authenticated user for logging")
            return
        }
        
        do {
            _ = try await saveDream(
                userId: userId,
                prompt: prompt,
                interpretation: interpretation,
                celestialAdvice: nil,
                lumaGenerationId: nil,
                videoURL: remoteVideoURL,
                localFilename: nil
            )
        } catch {
            print("SupabaseService: Failed to log dream - \(error.localizedDescription)")
        }
    }
}

