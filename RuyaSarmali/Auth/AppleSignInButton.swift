import SwiftUI
import AuthenticationServices
import CryptoKit

struct AppleSignInButton: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @State private var currentNonce: String?
    
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.email, .fullName]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleSignInResult(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .cornerRadius(28)
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idTokenString = String(data: identityToken, encoding: .utf8),
               let nonce = currentNonce {
                
                Task {
                    do {
                        try await authService.signInWithApple(idToken: idTokenString, nonce: nonce)
                    } catch {
                        print("Apple Sign-In failed: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign-In error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Nonce Generation
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Glassmorphism Styled Apple Button

struct GlassAppleSignInButton: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @State private var currentNonce: String?
    
    var body: some View {
        Button(action: initiateAppleSignIn) {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.title2)
                Text("Apple ile Devam Et")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 28))
    }
    
    private func initiateAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            AppleSignInButton()
            GlassAppleSignInButton()
        }
        .padding()
    }
}
