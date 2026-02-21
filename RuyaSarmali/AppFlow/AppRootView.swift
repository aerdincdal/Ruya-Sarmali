import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            switch appViewModel.flow {
            case .splash:
                SplashSequenceView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(
                    pages: OnboardingPage.sampleData,
                    onSkip: appViewModel.completeOnboarding,
                    onFinish: appViewModel.completeOnboarding
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .auth:
                RegistrationView(onRegistered: appViewModel.completeRegistration)
                    .transition(.opacity)
            case .main:
                MainExperienceView()
                    .environmentObject(themeManager)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: appViewModel.flow)
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
            .environmentObject(AppViewModel())
            .environmentObject(ThemeManager())
    }
}
