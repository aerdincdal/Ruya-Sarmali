import SwiftUI

struct ForgotPasswordFlow: View {
    enum Step {
        case request
        case reset
    }

    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var step: Step = .request

    var body: some View {
        NavigationStack {
            ZStack {
                AstroBackgroundView()
                VStack(spacing: 24) {
                    if step == .request {
                        recoveryRequest
                    } else {
                        passwordReset
                    }
                    Button(step == .request ? "Kurtarma Bağlantısı Gönder" : "Şifreyi Güncelle") {
                        if step == .request {
                            step = .reset
                        } else {
                            dismiss()
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                    .disabled(!isStepValid)
                }
                .padding(24)
            }
            .navigationTitle("Şifre Kurtarma")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var recoveryRequest: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("E-posta adresini paylaş, sana güvenli kurtarma bağlantısı gönderelim.")
                .foregroundColor(.white)
            TextField("E-posta", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private var passwordReset: some View {
        VStack(alignment: .leading, spacing: 12) {
            SecureField("Yeni şifre", text: $newPassword)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
            SecureField("Yeni şifre (tekrar)", text: $confirmPassword)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private var isStepValid: Bool {
        switch step {
        case .request:
            return email.contains("@")
        case .reset:
            return newPassword.count >= 8 && newPassword == confirmPassword
        }
    }
}
