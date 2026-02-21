import SwiftUI

struct SplashSlide: Identifiable {
    let id = UUID()
    let titleKey: String
    let subtitleKey: String
    
    var title: String { LocalizationManager.shared.localized(titleKey) }
    var subtitle: String { LocalizationManager.shared.localized(subtitleKey) }
}

struct SplashSequenceView: View {
    private let slides: [SplashSlide] = [
        SplashSlide(titleKey: "splash_1_title", subtitleKey: "splash_1_subtitle"),
        SplashSlide(titleKey: "splash_2_title", subtitleKey: "splash_2_subtitle"),
        SplashSlide(titleKey: "splash_3_title", subtitleKey: "splash_3_subtitle"),
        SplashSlide(titleKey: "splash_4_title", subtitleKey: "splash_4_subtitle"),
        SplashSlide(titleKey: "splash_5_title", subtitleKey: "splash_5_subtitle")
    ]

    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AstroBackgroundView()
            VStack(spacing: 24) {
                Spacer()
                Text(slides[currentIndex].title)
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .scale))
                    .id(slides[currentIndex].title)
                    .accessibilityAddTraits(.isHeader)

                Text(slides[currentIndex].subtitle)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.75))
                    .transition(.opacity)
                    .id(slides[currentIndex].subtitle)

                Spacer()
                ProgressView(value: Double(currentIndex + 1), total: Double(slides.count))
                    .tint(.white)
                    .frame(maxWidth: 220)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .accessibilityLabel("Splash progression")
                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) {
                currentIndex = (currentIndex + 1) % slides.count
            }
        }
    }
}

struct SplashSequenceView_Previews: PreviewProvider {
    static var previews: some View {
        SplashSequenceView()
    }
}
