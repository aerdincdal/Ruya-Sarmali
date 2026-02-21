import Foundation
import AuthenticationServices

// MARK: - Auth Models

struct AuthUser: Codable, Identifiable {
    let id: String
    let email: String?
    let username: String?
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isTokenExpired: Bool {
        Date() >= expiresAt
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let userMetadata: UserMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }
}

struct UserMetadata: Codable {
    let username: String?
}

struct AuthError: Codable {
    let error: String?
    let errorDescription: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
    }
    
    var displayMessage: String {
        message ?? errorDescription ?? error ?? "Bilinmeyen hata"
    }
}

// MARK: - SupabaseAuthService

@MainActor
final class SupabaseAuthService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// User is authenticated if they have a valid session (even if access token is expired, refresh token can renew it)
    var isAuthenticated: Bool { currentUser != nil && !currentUser!.refreshToken.isEmpty }
    
    // MARK: - Private Properties
    
    private let baseURL: URL
    private let anonKey: String
    private let session: URLSession
    private let keychain = KeychainStore()
    
    private let userKey = "supabase_current_user"
    
    // MARK: - Initialization
    
    init() {
        guard let urlString = Secrets.value(for: .supabaseURL),
              let url = URL(string: urlString),
              let key = Secrets.value(for: .supabaseAnonKey) else {
            fatalError("Supabase credentials not configured")
        }
        
        self.baseURL = url
        self.anonKey = key
        self.session = .shared
        
        Task { await loadStoredSession() }
    }
    
    // MARK: - Public Methods
    
    /// Email ve şifre ile kayıt
    func signUp(email: String, password: String, username: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/signup")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct SignUpPayload: Encodable {
            let email: String
            let password: String
            let data: [String: String]?
        }
        
        let payload = SignUpPayload(
            email: email,
            password: password,
            data: username != nil ? ["username": username!] : nil
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        // Debug: Print raw response
        if let responseStr = String(data: data, encoding: .utf8) {
            print("🔐 Supabase Signup Response: \(responseStr.prefix(500))")
        }
        
        try validateResponse(response, data: data)
        
        // Try to decode as full session first (when email confirmation is disabled)
        if let authSession = try? JSONDecoder().decode(AuthSession.self, from: data) {
            let user = mapSessionToUser(authSession)
            currentUser = user
            saveUserToKeychain(user)
            print("🔐 Signup successful with full session")
            return
        }
        
        // If email confirmation is enabled, Supabase returns just user info without tokens
        // In this case, we need to tell user to check their email
        struct SignupOnlyResponse: Codable {
            let id: String
            let email: String?
            let confirmation_sent_at: String?
        }
        
        if let signupOnly = try? JSONDecoder().decode(SignupOnlyResponse.self, from: data) {
            print("🔐 Signup successful - email confirmation may be required")
            // Create a temporary user without valid tokens (user needs to confirm email then sign in)
            throw NSError(
                domain: "SupabaseAuthService",
                code: 200,
                userInfo: [NSLocalizedDescriptionKey: "Kayıt başarılı! Lütfen e-postanızı kontrol edin ve doğrulama linkine tıklayın, ardından giriş yapın."]
            )
        }
        
        // Fallback error
        throw NSError(
            domain: "SupabaseAuthService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Kayıt yanıtı işlenemedi. Lütfen tekrar deneyin."]
        )
    }
    
    /// Email ve şifre ile giriş
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/token")
        var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct SignInPayload: Encodable {
            let email: String
            let password: String
        }
        
        request.httpBody = try JSONEncoder().encode(SignInPayload(email: email, password: password))
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let authSession = try JSONDecoder().decode(AuthSession.self, from: data)
        let user = mapSessionToUser(authSession)
        currentUser = user
        saveUserToKeychain(user)
    }
    
    /// Apple ID ile giriş
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/token")
        var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct AppleSignInPayload: Encodable {
            let provider: String
            let id_token: String
            let nonce: String
        }
        
        request.httpBody = try JSONEncoder().encode(AppleSignInPayload(
            provider: "apple",
            id_token: idToken,
            nonce: nonce
        ))
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let authSession = try JSONDecoder().decode(AuthSession.self, from: data)
        let user = mapSessionToUser(authSession)
        currentUser = user
        saveUserToKeychain(user)
    }
    
    /// Token yenileme
    func refreshToken() async throws {
        guard let user = currentUser else { return }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/token")
        var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct RefreshPayload: Encodable {
            let refresh_token: String
        }
        
        request.httpBody = try JSONEncoder().encode(RefreshPayload(refresh_token: user.refreshToken))
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let authSession = try JSONDecoder().decode(AuthSession.self, from: data)
        let newUser = mapSessionToUser(authSession)
        currentUser = newUser
        saveUserToKeychain(newUser)
    }
    
    /// OTP gonder (Magic Link alternatifi)
    func sendOTP(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/otp")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct OTPPayload: Encodable {
            let email: String
            let create_user: Bool
        }
        
        request.httpBody = try JSONEncoder().encode(OTPPayload(email: email, create_user: true))
        
        let (data, response) = try await session.data(for: request)
        
        if let responseStr = String(data: data, encoding: .utf8) {
            print("OTP Send Response: \(responseStr.prefix(300))")
        }
        
        try validateResponse(response, data: data)
        print("OTP sent successfully to \(email)")
    }
    
    /// OTP dogrula
    func verifyOTP(email: String, token: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/verify")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        struct VerifyPayload: Encodable {
            let email: String
            let token: String
            let type: String
        }
        
        request.httpBody = try JSONEncoder().encode(VerifyPayload(email: email, token: token, type: "email"))
        
        let (data, response) = try await session.data(for: request)
        
        if let responseStr = String(data: data, encoding: .utf8) {
            print("OTP Verify Response: \(responseStr.prefix(300))")
        }
        
        try validateResponse(response, data: data)
        
        let authSession = try JSONDecoder().decode(AuthSession.self, from: data)
        let user = mapSessionToUser(authSession)
        currentUser = user
        saveUserToKeychain(user)
        print("OTP verification successful")
    }
    
    /// Cikis yap
    func signOut() {
        currentUser = nil
        keychain.delete(key: userKey)
    }
    
    /// Geçerli access token'ı al (gerekirse yenile)
    func getValidAccessToken() async throws -> String {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Oturum açık değil"])
        }
        
        if user.isTokenExpired {
            try await refreshToken()
        }
        
        return currentUser?.accessToken ?? ""
    }
    
    /// Handle auth callback from deep link (email verification)
    func handleAuthCallback(accessToken: String, refreshToken: String, expiresIn: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user info with the access token
        let endpoint = baseURL.appendingPathComponent("auth/v1/user")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await session.data(for: request)
        
        if let responseStr = String(data: data, encoding: .utf8) {
            print("🔐 User info response: \(responseStr.prefix(300))")
        }
        
        try validateResponse(response, data: data)
        
        let supabaseUser = try JSONDecoder().decode(SupabaseUser.self, from: data)
        
        let user = AuthUser(
            id: supabaseUser.id,
            email: supabaseUser.email,
            username: supabaseUser.userMetadata?.username,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
        
        currentUser = user
        saveUserToKeychain(user)
        print("🔐 ✅ User authenticated via deep link callback")
    }
    
    // MARK: - Private Methods
    
    private func loadStoredSession() async {
        guard let data = keychain.data(forKey: userKey),
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            return
        }
        
        currentUser = user
        
        if user.isTokenExpired {
            do {
                try await refreshToken()
            } catch {
                signOut()
            }
        }
    }
    
    private func saveUserToKeychain(_ user: AuthUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        keychain.set(data, forKey: userKey)
    }
    
    private func mapSessionToUser(_ session: AuthSession) -> AuthUser {
        AuthUser(
            id: session.user.id,
            email: session.user.email,
            username: session.user.userMetadata?.username,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(session.expiresIn))
        )
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yanıt"])
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            if let authError = try? JSONDecoder().decode(AuthError.self, from: data) {
                throw NSError(domain: "SupabaseAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: authError.displayMessage])
            }
            throw NSError(domain: "SupabaseAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Kimlik doğrulama hatası: \(httpResponse.statusCode)"])
        }
    }
}

