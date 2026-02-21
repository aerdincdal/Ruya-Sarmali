import SwiftUI

struct RegistrationView: View {
    let onRegistered: () -> Void

    @EnvironmentObject private var authService: SupabaseAuthService
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var showOTPVerification = false
    @State private var policySheet: PolicySheet?
    @State private var acceptedTerms = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AstroBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroCard
                        emailInputCard
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red.opacity(0.9))
                                .font(.footnote)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        termsCheckbox
                        
                        sendCodeButton
                        
                        infoText
                    }
                    .padding(.vertical, 36)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                .onTapGesture {
                    isEmailFocused = false
                }
            }
            .sheet(item: $policySheet) { sheet in
                PolicyDocumentView(sheet: sheet)
            }
            .navigationDestination(isPresented: $showOTPVerification) {
                OTPVerificationView(email: email) {
                    onRegistered()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color(hex: 0xE6B6FF))
                Text(L10n.appName)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Text(L10n.registrationTitle)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            Text(L10n.registrationSubtitle)
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(LinearGradient(colors: [Color.white.opacity(0.9), Color.purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 40)
        )
    }
    
    private var emailInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L10n.emailLabel, systemImage: "envelope.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField(L10n.emailPlaceholder, text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .focused($isEmailFocused)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(L10n.emailHint)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private var termsCheckbox: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                acceptedTerms.toggle()
                AppServices.haptic.light()
            } label: {
                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(acceptedTerms ? Color(hex: 0xC28BFF) : .white.opacity(0.7))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.termsAccept)
                    .font(.footnote)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Button(L10n.termsOfService) {
                        policySheet = .terms
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: 0xE6B6FF))
                    
                    Button(L10n.privacyPolicy) {
                        policySheet = .privacy
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: 0xE6B6FF))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
    }
    
    private var sendCodeButton: some View {
        Button(action: sendOTPCode) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "envelope.badge.fill")
                    Text(L10n.sendCode)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 24))
        .disabled(!isValidEmail || !acceptedTerms || isLoading)
        .opacity(isValidEmail && acceptedTerms ? 1 : 0.5)
    }
    
    private var infoText: some View {
        VStack(spacing: 8) {
            Text(L10n.quickSecureLogin)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            
            Text(L10n.noPasswordNeeded)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text("info@mirleon.com")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 8)
        }
        .padding(.top, 20)
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendOTPCode() {
        isEmailFocused = false
        errorMessage = nil
        isLoading = true
        AppServices.haptic.medium()
        
        Task {
            do {
                try await authService.sendOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                await MainActor.run {
                    isLoading = false
                    AppServices.haptic.success()
                    showOTPVerification = true
                }
            } catch let error as NSError {
                await MainActor.run {
                    AppServices.haptic.error()
                    if error.localizedDescription.contains("rate") {
                        errorMessage = L10n.errorTooManyAttempts
                    } else if error.localizedDescription.contains("invalid") {
                        errorMessage = L10n.errorInvalidEmail
                    } else {
                        errorMessage = L10n.errorNetwork
                    }
                    isLoading = false
                }
            }
        }
    }
}

private enum PolicySheet: Identifiable {
    case terms
    case privacy

    var id: String {
        switch self {
        case .terms: return "terms"
        case .privacy: return "privacy"
        }
    }

    var title: String {
        switch self {
        case .terms: return L10n.termsOfService
        case .privacy: return L10n.privacyPolicy
        }
    }

    var bodyText: String {
        switch self {
        case .terms:
            return """
\(L10n.appName) Kullanıcı Sözleşmesi

1. Hizmetlerimizi kullanarak sağladığın tüm içeriklerin telif hakkı sende kalır, ancak içerikleri üretmek ve saklamak amacıyla dünya çapında devredilebilir olmayan bir lisans vermeyi kabul edersin.

2. Hesap bilgilerini gizli tutmak senin sorumluluğundadır. Platformda paylaştığın rüyalar, sen paylaşmayı seçmedikçe başka kullanıcılarla eşleştirilmez.

3. Üretilen videolar üçüncü parti medya servisleri üzerinden sunulur; bu servislerin teknik sınırlamaları için uygulama herhangi bir garanti vermez.

4. Platformu kullanırken yürürlükteki tüm yasalara, Apple App Store yönergelerine ve topluluk kurallarına uyacağını taahhüt edersin.

5. Hizmet kötüye kullanım, spam veya hak ihlali tespit edildiğinde hesabının askıya alınabileceğini kabul edersin.

6. Tüm sözleşme ve destek talepleri için info@mirleon.com adresine yazabilirsin.
"""
        case .privacy:
            return """
Gizlilik ve Veri İşleme Bildirimi

• Rüya metinleri ve üretilen videolar cihazında şifreli olarak saklanır.

• Paylaşmayı seçtiğinde Supabase altyapısına yalnızca oluşturma zamanı, içerik özeti ve isteğe bağlı video bağlantısı aktarılır.

• Oturum bilgileri Keychain/AppStorage üzerinde cihazın kendisinde korunur.

• Analitik ve hata kayıtları anonimdir; kişisel veriler üçüncü taraflara satılmaz.

• Herhangi bir zamanda info@mirleon.com adresine yazarak verilerinin silinmesini talep edebilirsin.
"""
        }
    }
}

private struct PolicyDocumentView: View {
    let sheet: PolicySheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(sheet.bodyText)
                    .foregroundColor(.primary)
                    .padding()
            }
            .navigationTitle(sheet.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}
