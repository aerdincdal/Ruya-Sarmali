import SwiftUI

struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let titleKey: String
    let subtitleKey: String
    let illustration: String
    
    var title: String { LocalizationManager.shared.localized(titleKey) }
    var subtitle: String { LocalizationManager.shared.localized(subtitleKey) }

    static let sampleData: [OnboardingPage] = [
        OnboardingPage(titleKey: "onboarding_1_title",
                       subtitleKey: "onboarding_1_subtitle",
                       illustration: "sparkles"),
        OnboardingPage(titleKey: "onboarding_2_title",
                       subtitleKey: "onboarding_2_subtitle",
                       illustration: "lock.shield"),
        OnboardingPage(titleKey: "onboarding_3_title",
                       subtitleKey: "onboarding_3_subtitle",
                       illustration: "moon.stars"),
        OnboardingPage(titleKey: "onboarding_4_title",
                       subtitleKey: "onboarding_4_subtitle",
                       illustration: "square.and.arrow.up")
    ]
}

struct OnboardingView: View {
    let pages: [OnboardingPage]
    let onSkip: () -> Void
    let onFinish: () -> Void

    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            AstroBackgroundView()
            VStack(spacing: 32) {
                TabView(selection: $currentIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                            .padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 420)

                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { dotIndex in
                        Circle()
                            .fill(dotIndex == currentIndex ? Color.accentColor : Color.white.opacity(0.3))
                            .frame(width: dotIndex == currentIndex ? 12 : 8, height: dotIndex == currentIndex ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }

                VStack(spacing: 16) {
                    Button(action: advance) {
                        Text(currentIndex == pages.count - 1 ? L10n.start : L10n.next)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                    .accessibilityLabel(currentIndex == pages.count - 1 ? "Get Started" : "Next onboarding page")

                    Button(action: onSkip) {
                        Text(L10n.skip)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 26, tint: .white.opacity(0.8)))
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 40)
            .padding(.bottom, 48)
        }
        .onAppear { UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentColor) }
    }

    private func advance() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
        } else {
            onFinish()
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: page.illustration)
                .symbolRenderingMode(.palette)
                .font(.system(size: 90, weight: .light))
                .foregroundStyle(Color.white.opacity(0.95), Color.purple.opacity(0.6))
                .padding(36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                        .blendMode(.overlay)
                )

            Text(page.title)
                .font(.title).bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(.thinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
