import SwiftUI
import Combine

enum AppFlowState: Equatable {
    case splash
    case onboarding
    case auth
    case main
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var flow: AppFlowState = .splash
    @AppStorage("ruya_onboarding_complete") private var hasCompletedOnboarding: Bool = false
    @AppStorage("ruya_is_registered") private var isRegistered: Bool = false
    private var splashTask: Task<Void, Never>?

    init() {
        startSplashSequence()
    }

    func startSplashSequence() {
        splashTask?.cancel()
        splashTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4.5))
            await MainActor.run {
                self?.evaluateInitialState()
            }
        }
    }

    func evaluateInitialState() {
        if hasCompletedOnboarding {
            flow = isRegistered ? .main : .auth
        } else {
            flow = .onboarding
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        flow = isRegistered ? .main : .auth
    }

    func completeRegistration() {
        isRegistered = true
        flow = .main
    }

    func requestAuthentication() {
        flow = .auth
    }

    func signOut() {
        isRegistered = false
        flow = .auth
    }
}
