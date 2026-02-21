import SwiftUI

struct LiquidGlassButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 32
    var tint: Color = Color.white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(tint)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(configuration.isPressed ? 0.7 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LinearGradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.4)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 18)
                    .glow(color: Color.purple.opacity(0.4), radius: configuration.isPressed ? 8 : 22)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

private extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color.opacity(0.8), radius: radius)
    }
}
