import SwiftUI

/// OTP Doğrulama Ekranı - 6 haneli kod ile giriş
struct OTPVerificationView: View {
    let email: String
    let onVerified: () -> Void
    
    @EnvironmentObject private var authService: SupabaseAuthService
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var otpCode: [String] = Array(repeating: "", count: 6)
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var resendCountdown = 60
    @State private var canResend = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        ZStack {
            AstroBackgroundView()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: 0xE6B6FF))
                    
                    Text(L10n.otpTitle)
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text(String(format: L10n.otpSubtitle, email))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // OTP Alanları
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPTextField(
                            text: $otpCode[index],
                            isFocused: focusedField == index
                        )
                        .focused($focusedField, equals: index)
                        .onChange(of: otpCode[index]) { newValue in
                            handleTextChange(index: index, newValue: newValue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Doğrula butonu
                Button(action: verifyOTP) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(L10n.otpVerify)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 20))
                .disabled(otpCode.joined().count != 6 || isVerifying)
                .opacity(otpCode.joined().count == 6 ? 1 : 0.5)
                .padding(.horizontal, 32)
                
                // Kod tekrar gönder
                VStack(spacing: 8) {
                    if canResend {
                        Button(L10n.otpResend) {
                            resendOTP()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: 0xE6B6FF))
                    } else {
                        Text(String(format: L10n.otpResendIn, resendCountdown))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            focusedField = 0
            startResendTimer()
        }
    }
    
    private func handleTextChange(index: Int, newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        
        if filtered.count > 1 {
            let characters = Array(filtered.prefix(6))
            for (i, char) in characters.enumerated() {
                otpCode[i] = String(char)
            }
            focusedField = min(characters.count, 5)
        } else if filtered.count == 1 {
            otpCode[index] = filtered
            if index < 5 {
                focusedField = index + 1
            }
        } else if filtered.isEmpty && !newValue.isEmpty {
            otpCode[index] = ""
        }
        
        if otpCode.joined().count == 6 {
            verifyOTP()
        }
    }
    
    private func verifyOTP() {
        let code = otpCode.joined()
        guard code.count == 6 else { return }
        
        isVerifying = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.verifyOTP(email: email, token: code)
                await MainActor.run {
                    AppServices.haptic.success()
                    onVerified()
                }
            } catch {
                await MainActor.run {
                    AppServices.haptic.error()
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("invalid") || errorDesc.contains("expired") {
                        errorMessage = L10n.otpInvalidOrExpired
                    } else if errorDesc.contains("network") {
                        errorMessage = L10n.errorNetwork
                    } else {
                        errorMessage = L10n.otpVerificationFailed
                    }
                    isVerifying = false
                    otpCode = Array(repeating: "", count: 6)
                    focusedField = 0
                }
            }
        }
    }
    
    private func resendOTP() {
        canResend = false
        resendCountdown = 60
        startResendTimer()
        errorMessage = nil
        
        Task {
            do {
                try await authService.sendOTP(email: email)
                await MainActor.run {
                    AppServices.haptic.success()
                }
            } catch {
                await MainActor.run {
                    AppServices.haptic.error()
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("rate") || errorDesc.contains("limit") {
                        errorMessage = L10n.errorTooManyAttempts
                    } else if errorDesc.contains("network") || errorDesc.contains("internet") {
                        errorMessage = L10n.errorNetwork
                    } else {
                        errorMessage = L10n.otpSendFailed
                    }
                }
            }
        }
    }
    
    private func startResendTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - OTP Metin Alanı
struct OTPTextField: View {
    @Binding var text: String
    let isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.title.weight(.bold))
            .foregroundColor(.white)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color(hex: 0xE6B6FF) : Color.white.opacity(0.2),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
