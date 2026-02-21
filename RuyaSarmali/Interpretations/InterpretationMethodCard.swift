import SwiftUI

/// Yorum metodu kartı - glassmorphism tasarımıyla
struct InterpretationMethodCard: View {
    let method: InterpretationMethod
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var gradientColors: [Color] {
        method.gradient.compactMap { Color(hex: $0) }
    }
    
    var body: some View {
        Button(action: {
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: method.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(method.subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(isSelected ? 0.95 : 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isSelected 
                                    ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? gradientColors.first?.opacity(0.3) ?? .clear : .clear, radius: 12, x: 0, y: 6)
            )
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isLoading)
    }
}

// MARK: - Color Extension for Hex String
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(InterpretationMethod.allCases) { method in
                InterpretationMethodCard(
                    method: method,
                    isSelected: method == .astrological,
                    isLoading: false
                ) {}
            }
        }
        .padding()
    }
}
