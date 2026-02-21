import SwiftUI
import UserNotifications

@main
struct RuyaSarmaliApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authService = SupabaseAuthService()
    @StateObject private var dreamRepository: DreamRepository
    @StateObject private var supabaseService: SupabaseService
    @StateObject private var generationViewModel: DreamGenerationViewModel
    @StateObject private var creditStore: CreditStore
    
    // Use singleton pattern for CreditManager
    private let creditManager = CreditManager.shared

    init() {
        // Initialize core services
        let repository = DreamRepository()
        let creditStore = CreditStore(packages: CreditManager.packages)
        
        // Initialize API services
        let interpreter = DreamInterpretationService(apiKey: Secrets.value(for: .openAIKey))
        let lumaService = LumaAIService(apiKey: Secrets.value(for: .lumaAPIKey))
        
        // Initialize Supabase
        let supabaseConfig = SupabaseConfig(
            baseURLString: Secrets.value(for: .supabaseURL),
            anonKey: Secrets.value(for: .supabaseAnonKey),
            tableName: Secrets.value(for: .supabaseTable)
        )
        let supabaseService = SupabaseService(config: supabaseConfig) ?? {
            fatalError("Failed to initialize SupabaseService")
        }()
        
        // Initialize local storage
        let sqliteStore = SQLiteDreamStore()
        
        // Initialize backend coordinator
        let coordinator = DreamBackendCoordinator(
            interpreter: interpreter,
            lumaService: lumaService,
            supabase: supabaseService,
            sqliteStore: sqliteStore,
            fallbackSynthesizer: DreamVideoSynthesizer()
        )
        
        // Assign StateObjects
        _dreamRepository = StateObject(wrappedValue: repository)
        _supabaseService = StateObject(wrappedValue: supabaseService)
        _generationViewModel = StateObject(wrappedValue: DreamGenerationViewModel(
            repository: repository,
            backend: coordinator,
            creditManager: CreditManager.shared
        ))
        _creditStore = StateObject(wrappedValue: creditStore)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
                .environmentObject(themeManager)
                .environmentObject(authService)
                .environmentObject(dreamRepository)
                .environmentObject(supabaseService)
                .environmentObject(generationViewModel)
                .environmentObject(creditManager)
                .environmentObject(creditStore)
                .onAppear {
                    // Connect auth service to supabase service
                    supabaseService.setAuthService(authService)
                    
                    // Clear notification badge on app open
                    UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
                }
                .onChange(of: authService.isAuthenticated) { isAuthenticated in
                    if isAuthenticated {
                        appViewModel.completeRegistration()
                        
                        // Request notification permission after authentication
                        Task {
                            _ = await NotificationManager.shared.requestPermission()
                        }
                    } else {
                        appViewModel.requestAuthentication()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }
    
    /// Handle deep links from Supabase email verification
    private func handleDeepLink(url: URL) {
        print("📱 Deep Link received: \(url)")
        
        // Parse the URL - Supabase sends tokens in the fragment
        // Format: ruyasarmali://auth/callback#access_token=...&refresh_token=...
        guard let fragment = url.fragment else {
            print("📱 No fragment in URL")
            return
        }
        
        // Parse fragment parameters
        var params: [String: String] = [:]
        for component in fragment.components(separatedBy: "&") {
            let parts = component.components(separatedBy: "=")
            if parts.count == 2 {
                params[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
            }
        }
        
        // Check if this is an auth callback with tokens
        if let accessToken = params["access_token"],
           let refreshToken = params["refresh_token"],
           let expiresIn = params["expires_in"] {
            print("📱 Auth tokens received from deep link")
            
            Task { @MainActor in
                do {
                    try await authService.handleAuthCallback(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: Int(expiresIn) ?? 3600
                    )
                    print("📱 ✅ Auth session restored from deep link")
                } catch {
                    print("📱 ❌ Failed to handle auth callback: \(error)")
                }
            }
        }
    }
}
