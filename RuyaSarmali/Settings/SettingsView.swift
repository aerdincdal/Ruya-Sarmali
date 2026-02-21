import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var creditManager: CreditManager
    @EnvironmentObject private var authService: SupabaseAuthService
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var notificationsAuthorized = false
    @State private var expandedSections: Set<String> = ["account"]
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var showFeedback = false
    @State private var feedbackText = ""
    @State private var showShareSheet = false
    @State private var showLanguagePicker = false
    @AppStorage("dailyReminder") private var dailyReminder = true
    @AppStorage("reminderTime") private var reminderTimeData: Data = Data()
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("autoSaveToPhotos") private var autoSaveToPhotos = false
    @AppStorage("showOnboarding") private var showOnboarding = false

    var body: some View {
        ZStack {
            AstroBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    accountSection
                    creditsSection
                    notificationsSection
                    appSettingsSection
                    privacySection
                    supportSection
                    aboutSection
                    legalSection
                    dangerZone
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(L10n.settings)
        .sheet(isPresented: $showPaywall) {
            CreditPaywallView()
        }
        .sheet(isPresented: $showFeedback) {
            feedbackSheet
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                "\(L10n.appName) - \(L10n.registrationTitle)! https://apps.apple.com/app/ruya-sarmali"
            ], excludedActivityTypes: nil)
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .alert(L10n.deleteAccount, isPresented: $showDeleteConfirmation) {
            Button(L10n.cancel, role: .cancel) { }
            Button(L10n.deleteAccount, role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(L10n.deleteAccountConfirm)
        }
    }
    
    // MARK: - Hesap Bilgileri
    private var accountSection: some View {
        settingsSection(id: "account", title: L10n.accountInfo, systemImage: "person.crop.circle.fill") {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: 0x6B4FA2), Color(hex: 0x9B6BC3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        
                        Text(String((authService.currentUser?.username ?? authService.currentUser?.email ?? "U").prefix(1)).uppercased())
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let username = authService.currentUser?.username, !username.isEmpty {
                            Text(username)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(L10n.verifiedAccount)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                
                Button(action: {
                    authService.signOut()
                    appViewModel.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text(L10n.signOut)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 16, tint: Color(hex: 0xFF6B6B)))
            }
        }
    }
    
    // MARK: - Kredi Durumu
    private var creditsSection: some View {
        settingsSection(id: "credits", title: L10n.creditAndPremium, systemImage: "star.circle.fill") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.currentBalance)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(creditManager.balance)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(L10n.credits)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0xE6B6FF))
                }
                .padding()
                .background(
                    LinearGradient(colors: [Color(hex: 0x2A1B47), Color(hex: 0x1A1030)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20)
                )
                
                Text(creditManager.demoLabel())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: { showPaywall = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(L10n.buyCredits)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 16, tint: Color(hex: 0xFFD700)))
            }
        }
    }
    
    // MARK: - Bildirimler
    private var notificationsSection: some View {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        
        return settingsSection(id: "notifications", title: L10n.notifications, systemImage: "bell.badge.fill") {
            VStack(spacing: 16) {
                // Permission status
                if !notificationsAuthorized {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(isEnglish ? "Notifications disabled" : "Bildirimler kapalı")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Button(isEnglish ? "Enable" : "Etkinleştir") {
                            requestNotificationPermission()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(hex: 0xE6B6FF))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.15))
                    )
                }
                
                Toggle(isOn: Binding(
                    get: { dailyReminder && notificationsAuthorized },
                    set: { newValue in
                        dailyReminder = newValue
                        if newValue {
                            scheduleDailyReminder()
                        } else {
                            cancelDailyReminder()
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "alarm.fill")
                            .foregroundColor(Color(hex: 0xE6B6FF))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.dailyReminder)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text(L10n.dailyReminderDesc)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .tint(Color(hex: 0x9B6BC3))
                .disabled(!notificationsAuthorized)
                
                Toggle(isOn: $themeManager.enableNotifications) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color(hex: 0xE6B6FF))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.readyNotification)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text(L10n.readyNotificationDesc)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .tint(Color(hex: 0x9B6BC3))
                .disabled(!notificationsAuthorized)
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsAuthorized = granted
                if !granted {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.currentLanguage == .english ? "🌙 What did you dream?" : "🌙 Ne rüya gördün?"
        content.body = LocalizationManager.shared.currentLanguage == .english ? "Record your dream before it fades." : "Rüyanı unutmadan kaydet."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_dream_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_dream_reminder"])
    }
    
    // MARK: - Uygulama Ayarları
    private var appSettingsSection: some View {
        settingsSection(id: "app", title: L10n.appSettings, systemImage: "gearshape.fill") {
            VStack(spacing: 16) {
                settingsToggle(
                    title: L10n.soundEffects,
                    subtitle: L10n.soundEffectsDesc,
                    icon: "speaker.wave.2.fill",
                    isOn: $soundEnabled
                )
                
                settingsToggle(
                    title: L10n.hapticFeedback,
                    subtitle: L10n.hapticFeedbackDesc,
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: $hapticEnabled
                )
                
                settingsToggle(
                    title: L10n.autoSave,
                    subtitle: L10n.autoSaveDesc,
                    icon: "square.and.arrow.down.fill",
                    isOn: $autoSaveToPhotos
                )
                
                // Dil seçici
                Button(action: { showLanguagePicker = true }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(Color(hex: 0xE6B6FF))
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.language)
                                .foregroundColor(.white)
                            Text("\(localization.currentLanguage.flag) \(localization.currentLanguage.displayName)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Tema
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(Color(hex: 0xE6B6FF))
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.theme)
                            .foregroundColor(.white)
                        Text(L10n.cosmicPurple)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Gizlilik
    private var privacySection: some View {
        settingsSection(id: "privacy", title: L10n.privacyAndSecurity, systemImage: "lock.shield.fill") {
            VStack(alignment: .leading, spacing: 12) {
                privacyRow(icon: "checkmark.shield.fill", text: L10n.dataEncrypted, color: .green)
                privacyRow(icon: "icloud.slash.fill", text: L10n.offlineSupported, color: .blue)
                privacyRow(icon: "hand.raised.fill", text: L10n.noThirdPartySharing, color: .orange)
                privacyRow(icon: "trash.fill", text: L10n.deleteAnytime, color: .red)
            }
        }
    }
    
    // MARK: - Destek
    private var supportSection: some View {
        settingsSection(id: "support", title: L10n.support, systemImage: "questionmark.circle.fill") {
            VStack(spacing: 12) {
                settingsButton(icon: "envelope.fill", title: L10n.contactUs, subtitle: "info@mirleon.com") {
                    if let url = URL(string: "mailto:info@mirleon.com") {
                        UIApplication.shared.open(url)
                    }
                }
                
                settingsButton(icon: "star.fill", title: L10n.rateApp, subtitle: L10n.rateAppDesc) {
                    requestReview()
                }
                
                settingsButton(icon: "square.and.arrow.up.fill", title: L10n.shareWithFriend, subtitle: L10n.shareWithFriendDesc) {
                    showShareSheet = true
                }
                
                settingsButton(icon: "bubble.left.and.bubble.right.fill", title: L10n.sendFeedback, subtitle: L10n.sendFeedbackDesc) {
                    showFeedback = true
                }
                
                settingsButton(icon: "play.rectangle.fill", title: L10n.howToUse, subtitle: L10n.howToUseDesc) {
                    showOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Hakkında
    private var aboutSection: some View {
        settingsSection(id: "about", title: L10n.about, systemImage: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.version)
                        .foregroundColor(.white)
                    Spacer()
                    Text("1.0.0 (1)")
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack {
                    Text(L10n.developer)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Mirleon Labs")
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack {
                    Text(L10n.copyright)
                        .foregroundColor(.white)
                    Spacer()
                    Text("© 2024 \(L10n.appName)")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Yasal
    private var legalSection: some View {
        settingsSection(id: "legal", title: L10n.legal, systemImage: "doc.text.fill") {
            VStack(spacing: 12) {
                settingsButton(icon: "doc.text.fill", title: L10n.termsOfService, subtitle: nil) {
                    if let url = URL(string: "https://mirleon.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                
                settingsButton(icon: "hand.raised.fill", title: L10n.privacyPolicy, subtitle: nil) {
                    if let url = URL(string: "https://mirleon.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                
                settingsButton(icon: "doc.badge.gearshape.fill", title: L10n.openSourceLicenses, subtitle: nil) {
                    // Show licenses
                }
            }
        }
    }
    
    // MARK: - Tehlikeli Bölge
    private var dangerZone: some View {
        settingsSection(id: "danger", title: L10n.accountManagement, systemImage: "exclamationmark.triangle.fill") {
            VStack(spacing: 12) {
                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text(L10n.deleteAccount)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    // MARK: - Language Picker Sheet
    private var languagePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x0D0B14).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(AppLanguage.allCases) { language in
                        Button(action: {
                            AppServices.haptic.medium()
                            localization.setLanguage(language)
                            showLanguagePicker = false
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.title)
                                Text(language.displayName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                if localization.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: 0xE6B6FF))
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(L10n.language)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { showLanguagePicker = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Feedback Sheet
    private var feedbackSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x0D0B14).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(L10n.feedbackTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $feedbackText)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minHeight: 200)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    Button(L10n.send) {
                        sendFeedback()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 16))
                    .disabled(feedbackText.count < 10)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(L10n.sendFeedback)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { showFeedback = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func settingsSection<Content: View>(id: String, title: String, systemImage: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expandedSections.contains(id) },
            set: { isExpanded in
                withAnimation(.spring(response: 0.3)) {
                    if isExpanded {
                        expandedSections.insert(id)
                    } else {
                        expandedSections.remove(id)
                    }
                }
            }
        )) {
            content()
                .padding(.top, 12)
        } label: {
            Label(title, systemImage: systemImage)
                .foregroundColor(.white)
                .font(.headline)
        }
        .tint(.white)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func settingsToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: 0xE6B6FF))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: 0x9B6BC3))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func settingsButton(icon: String, title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: 0xE6B6FF))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func privacyRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
        }
    }
    
    // MARK: - Actions
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func sendFeedback() {
        showFeedback = false
        feedbackText = ""
    }
    
    private func deleteAccount() {
        authService.signOut()
        appViewModel.signOut()
    }
}
