import Foundation

enum SecretKey: String {
    case lumaAPIKey = "LUMAAI_API_KEY"
    case openAIKey = "OPENAI_API_KEY"
    case supabaseURL = "SUPABASE_URL"
    case supabaseAnonKey = "SUPABASE_ANON_KEY"
    case supabaseTable = "SUPABASE_DREAM_TABLE"
}

struct Secrets {
    /// Retrieves a secret value with the following priority:
    /// 1. Environment variable (for CI/CD or local overrides)
    /// 2. Info.plist (injected from xcconfig via Build Settings)
    /// 3. Returns nil if not found
    static func value(for key: SecretKey) -> String? {
        // Priority 1: Environment variable
        if let envValue = ProcessInfo.processInfo.environment[key.rawValue], !envValue.isEmpty {
            return envValue
        }
        
        // Priority 2: Info.plist (from xcconfig build settings)
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String, 
           !infoValue.isEmpty,
           !infoValue.hasPrefix("$(") { // Ignore unexpanded xcconfig variables
            return infoValue
        }
        
        // Not found - log warning in debug
        #if DEBUG
        print("⚠️ Secret key '\(key.rawValue)' not found. Check Secrets.xcconfig or environment variables.")
        #endif
        
        return nil
    }
}
