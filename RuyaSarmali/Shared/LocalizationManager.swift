import SwiftUI

// MARK: - Supported Languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Localization Manager
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("selectedLanguage") private var storedLanguage: String = "tr"
    @Published var currentLanguage: AppLanguage = .turkish
    @Published private(set) var bundle: Bundle = .main
    
    private init() {
        if let lang = AppLanguage(rawValue: storedLanguage) {
            currentLanguage = lang
        }
        updateBundle()
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        storedLanguage = language.rawValue
        updateBundle()
        objectWillChange.send()
    }
    
    private func updateBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = .main
            return
        }
        self.bundle = bundle
    }
    
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// MARK: - Localization Keys
enum L10n {
    // MARK: - App General
    static var appName: String { LocalizationManager.shared.localized("app_name") }
    static var close: String { LocalizationManager.shared.localized("close") }
    static var done: String { LocalizationManager.shared.localized("done") }
    static var cancel: String { LocalizationManager.shared.localized("cancel") }
    static var save: String { LocalizationManager.shared.localized("save") }
    static var delete: String { LocalizationManager.shared.localized("delete") }
    static var share: String { LocalizationManager.shared.localized("share") }
    static var error: String { LocalizationManager.shared.localized("error") }
    static var success: String { LocalizationManager.shared.localized("success") }
    static var loading: String { LocalizationManager.shared.localized("loading") }
    static var retry: String { LocalizationManager.shared.localized("retry") }
    
    // MARK: - Registration
    static var registrationTitle: String { LocalizationManager.shared.localized("registration_title") }
    static var registrationSubtitle: String { LocalizationManager.shared.localized("registration_subtitle") }
    static var emailLabel: String { LocalizationManager.shared.localized("email_label") }
    static var emailPlaceholder: String { LocalizationManager.shared.localized("email_placeholder") }
    static var emailHint: String { LocalizationManager.shared.localized("email_hint") }
    static var termsAccept: String { LocalizationManager.shared.localized("terms_accept") }
    static var termsOfService: String { LocalizationManager.shared.localized("terms_of_service") }
    static var privacyPolicy: String { LocalizationManager.shared.localized("privacy_policy") }
    static var sendCode: String { LocalizationManager.shared.localized("send_code") }
    static var quickSecureLogin: String { LocalizationManager.shared.localized("quick_secure_login") }
    static var noPasswordNeeded: String { LocalizationManager.shared.localized("no_password_needed") }
    
    // MARK: - OTP
    static var otpTitle: String { LocalizationManager.shared.localized("otp_title") }
    static var otpSubtitle: String { LocalizationManager.shared.localized("otp_subtitle") }
    static var otpVerify: String { LocalizationManager.shared.localized("otp_verify") }
    static var otpResend: String { LocalizationManager.shared.localized("otp_resend") }
    static var otpResendIn: String { LocalizationManager.shared.localized("otp_resend_in") }
    static var otpInvalidOrExpired: String { LocalizationManager.shared.localized("otp_invalid_or_expired") }
    static var otpVerificationFailed: String { LocalizationManager.shared.localized("otp_verification_failed") }
    static var otpSendFailed: String { LocalizationManager.shared.localized("otp_send_failed") }
    
    // MARK: - Errors
    static var errorTooManyAttempts: String { LocalizationManager.shared.localized("error_too_many_attempts") }
    static var errorInvalidEmail: String { LocalizationManager.shared.localized("error_invalid_email") }
    static var errorNetwork: String { LocalizationManager.shared.localized("error_network") }
    static var errorUnknown: String { LocalizationManager.shared.localized("error_unknown") }
    
    // MARK: - Dream Narration
    static var dreamNarrationTitle: String { LocalizationManager.shared.localized("dream_narration_title") }
    static var dreamNarrationSubtitle: String { LocalizationManager.shared.localized("dream_narration_subtitle") }
    static var dreamInputHint: String { LocalizationManager.shared.localized("dream_input_hint") }
    static var wordCount: String { LocalizationManager.shared.localized("word_count") }
    static var generateVideo: String { LocalizationManager.shared.localized("generate_video") }
    static var generating: String { LocalizationManager.shared.localized("generating") }
    static var creditBalance: String { LocalizationManager.shared.localized("credit_balance") }
    static var credits: String { LocalizationManager.shared.localized("credits") }
    static var viewCreditPackages: String { LocalizationManager.shared.localized("view_credit_packages") }
    
    // MARK: - Dream Interpretations
    static var interpretationsTitle: String { LocalizationManager.shared.localized("interpretations_title") }
    static var interpretationsSubtitle: String { LocalizationManager.shared.localized("interpretations_subtitle") }
    static var writeDream: String { LocalizationManager.shared.localized("write_dream") }
    static var selectMethod: String { LocalizationManager.shared.localized("select_method") }
    static var interpreting: String { LocalizationManager.shared.localized("interpreting") }
    
    // MARK: - Interpretation Methods
    static var methodAstrological: String { LocalizationManager.shared.localized("method_astrological") }
    static var methodAstrologicalDesc: String { LocalizationManager.shared.localized("method_astrological_desc") }
    static var methodIslamic: String { LocalizationManager.shared.localized("method_islamic") }
    static var methodIslamicDesc: String { LocalizationManager.shared.localized("method_islamic_desc") }
    static var methodPsychological: String { LocalizationManager.shared.localized("method_psychological") }
    static var methodPsychologicalDesc: String { LocalizationManager.shared.localized("method_psychological_desc") }
    static var methodNumerological: String { LocalizationManager.shared.localized("method_numerological") }
    static var methodNumerologicalDesc: String { LocalizationManager.shared.localized("method_numerological_desc") }
    static var methodTarot: String { LocalizationManager.shared.localized("method_tarot") }
    static var methodTarotDesc: String { LocalizationManager.shared.localized("method_tarot_desc") }
    static var methodMythological: String { LocalizationManager.shared.localized("method_mythological") }
    static var methodMythologicalDesc: String { LocalizationManager.shared.localized("method_mythological_desc") }
    
    // MARK: - Interpretation Result
    static var yourInterpretation: String { LocalizationManager.shared.localized("your_interpretation") }
    static var relationshipMessage: String { LocalizationManager.shared.localized("relationship_message") }
    static var createInstagramStory: String { LocalizationManager.shared.localized("create_instagram_story") }
    static var shareOnInstagram: String { LocalizationManager.shared.localized("share_on_instagram") }
    static var saveToGallery: String { LocalizationManager.shared.localized("save_to_gallery") }
    static var instagramStory: String { LocalizationManager.shared.localized("instagram_story") }
    
    // MARK: - Video Playback
    static var savedToGallery: String { LocalizationManager.shared.localized("saved_to_gallery") }
    static var videoSavedMessage: String { LocalizationManager.shared.localized("video_saved_message") }
    static var showMore: String { LocalizationManager.shared.localized("show_more") }
    static var showLess: String { LocalizationManager.shared.localized("show_less") }
    
    // MARK: - Settings
    static var settings: String { LocalizationManager.shared.localized("settings") }
    static var accountInfo: String { LocalizationManager.shared.localized("account_info") }
    static var verifiedAccount: String { LocalizationManager.shared.localized("verified_account") }
    static var signOut: String { LocalizationManager.shared.localized("sign_out") }
    static var creditAndPremium: String { LocalizationManager.shared.localized("credit_and_premium") }
    static var currentBalance: String { LocalizationManager.shared.localized("current_balance") }
    static var buyCredits: String { LocalizationManager.shared.localized("buy_credits") }
    static var notifications: String { LocalizationManager.shared.localized("notifications") }
    static var dailyReminder: String { LocalizationManager.shared.localized("daily_reminder") }
    static var dailyReminderDesc: String { LocalizationManager.shared.localized("daily_reminder_desc") }
    static var readyNotification: String { LocalizationManager.shared.localized("ready_notification") }
    static var readyNotificationDesc: String { LocalizationManager.shared.localized("ready_notification_desc") }
    static var appSettings: String { LocalizationManager.shared.localized("app_settings") }
    static var soundEffects: String { LocalizationManager.shared.localized("sound_effects") }
    static var soundEffectsDesc: String { LocalizationManager.shared.localized("sound_effects_desc") }
    static var hapticFeedback: String { LocalizationManager.shared.localized("haptic_feedback") }
    static var hapticFeedbackDesc: String { LocalizationManager.shared.localized("haptic_feedback_desc") }
    static var autoSave: String { LocalizationManager.shared.localized("auto_save") }
    static var autoSaveDesc: String { LocalizationManager.shared.localized("auto_save_desc") }
    static var theme: String { LocalizationManager.shared.localized("theme") }
    static var cosmicPurple: String { LocalizationManager.shared.localized("cosmic_purple") }
    static var language: String { LocalizationManager.shared.localized("language") }
    static var privacyAndSecurity: String { LocalizationManager.shared.localized("privacy_and_security") }
    static var dataEncrypted: String { LocalizationManager.shared.localized("data_encrypted") }
    static var offlineSupported: String { LocalizationManager.shared.localized("offline_supported") }
    static var noThirdPartySharing: String { LocalizationManager.shared.localized("no_third_party_sharing") }
    static var deleteAnytime: String { LocalizationManager.shared.localized("delete_anytime") }
    static var support: String { LocalizationManager.shared.localized("support") }
    static var contactUs: String { LocalizationManager.shared.localized("contact_us") }
    static var rateApp: String { LocalizationManager.shared.localized("rate_app") }
    static var rateAppDesc: String { LocalizationManager.shared.localized("rate_app_desc") }
    static var shareWithFriend: String { LocalizationManager.shared.localized("share_with_friend") }
    static var shareWithFriendDesc: String { LocalizationManager.shared.localized("share_with_friend_desc") }
    static var sendFeedback: String { LocalizationManager.shared.localized("send_feedback") }
    static var sendFeedbackDesc: String { LocalizationManager.shared.localized("send_feedback_desc") }
    static var howToUse: String { LocalizationManager.shared.localized("how_to_use") }
    static var howToUseDesc: String { LocalizationManager.shared.localized("how_to_use_desc") }
    static var about: String { LocalizationManager.shared.localized("about") }
    static var version: String { LocalizationManager.shared.localized("version") }
    static var developer: String { LocalizationManager.shared.localized("developer") }
    static var copyright: String { LocalizationManager.shared.localized("copyright") }
    static var legal: String { LocalizationManager.shared.localized("legal") }
    static var openSourceLicenses: String { LocalizationManager.shared.localized("open_source_licenses") }
    static var accountManagement: String { LocalizationManager.shared.localized("account_management") }
    static var deleteAccount: String { LocalizationManager.shared.localized("delete_account") }
    static var deleteAccountConfirm: String { LocalizationManager.shared.localized("delete_account_confirm") }
    static var feedbackTitle: String { LocalizationManager.shared.localized("feedback_title") }
    static var feedbackPlaceholder: String { LocalizationManager.shared.localized("feedback_placeholder") }
    static var send: String { LocalizationManager.shared.localized("send") }
    
    // MARK: - Tab Bar
    static var tabDream: String { LocalizationManager.shared.localized("tab_dream") }
    static var tabInterpretations: String { LocalizationManager.shared.localized("tab_interpretations") }
    static var tabArchive: String { LocalizationManager.shared.localized("tab_archive") }
    static var tabSettings: String { LocalizationManager.shared.localized("tab_settings") }
    
    // MARK: - Credits
    static var freeTrials: String { LocalizationManager.shared.localized("free_trials") }
    static var creditCost: String { LocalizationManager.shared.localized("credit_cost") }
    
    // MARK: - Credit Packages
    static var creditPackagesTitle: String { LocalizationManager.shared.localized("credit_packages_title") }
    static var boostCredits: String { LocalizationManager.shared.localized("boost_credits") }
    static var creditPackagesSubtitle: String { LocalizationManager.shared.localized("credit_packages_subtitle") }
    static var purchaseSecurity: String { LocalizationManager.shared.localized("purchase_security") }
    static var mostPopular: String { LocalizationManager.shared.localized("most_popular") }
    static var processing: String { LocalizationManager.shared.localized("processing") }
    static var purchase: String { LocalizationManager.shared.localized("purchase") }
    static var creditsAdded: String { LocalizationManager.shared.localized("credits_added") }
    static var info: String { LocalizationManager.shared.localized("info") }
    static var interpretDream: String { LocalizationManager.shared.localized("interpret_dream") }
    static var currentDream: String { LocalizationManager.shared.localized("current_dream") }
    
    // MARK: - Onboarding
    static var onboarding1Title: String { LocalizationManager.shared.localized("onboarding_1_title") }
    static var onboarding1Subtitle: String { LocalizationManager.shared.localized("onboarding_1_subtitle") }
    static var onboarding2Title: String { LocalizationManager.shared.localized("onboarding_2_title") }
    static var onboarding2Subtitle: String { LocalizationManager.shared.localized("onboarding_2_subtitle") }
    static var onboarding3Title: String { LocalizationManager.shared.localized("onboarding_3_title") }
    static var onboarding3Subtitle: String { LocalizationManager.shared.localized("onboarding_3_subtitle") }
    static var onboarding4Title: String { LocalizationManager.shared.localized("onboarding_4_title") }
    static var onboarding4Subtitle: String { LocalizationManager.shared.localized("onboarding_4_subtitle") }
    static var start: String { LocalizationManager.shared.localized("start") }
    static var next: String { LocalizationManager.shared.localized("next") }
    static var skip: String { LocalizationManager.shared.localized("skip") }
    
    // MARK: - Splash
    static var splash1Title: String { LocalizationManager.shared.localized("splash_1_title") }
    static var splash1Subtitle: String { LocalizationManager.shared.localized("splash_1_subtitle") }
    static var splash2Title: String { LocalizationManager.shared.localized("splash_2_title") }
    static var splash2Subtitle: String { LocalizationManager.shared.localized("splash_2_subtitle") }
    static var splash3Title: String { LocalizationManager.shared.localized("splash_3_title") }
    static var splash3Subtitle: String { LocalizationManager.shared.localized("splash_3_subtitle") }
    static var splash4Title: String { LocalizationManager.shared.localized("splash_4_title") }
    static var splash4Subtitle: String { LocalizationManager.shared.localized("splash_4_subtitle") }
    static var splash5Title: String { LocalizationManager.shared.localized("splash_5_title") }
    static var splash5Subtitle: String { LocalizationManager.shared.localized("splash_5_subtitle") }
    
    // MARK: - Other
    static var dreamBecomingVideo: String { LocalizationManager.shared.localized("dream_becoming_video") }
    static var dreamSummary: String { LocalizationManager.shared.localized("dream_summary") }
    static var astroInterpretation: String { LocalizationManager.shared.localized("astro_interpretation") }
    static var astroInterpretationHint: String { LocalizationManager.shared.localized("astro_interpretation_hint") }
    static var dreamDetailPrompt: String { LocalizationManager.shared.localized("dream_detail_prompt") }
}
