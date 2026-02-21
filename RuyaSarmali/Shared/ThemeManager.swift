import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published var enableNotifications: Bool = true

    var preferredColorScheme: ColorScheme? { .dark }

    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x02040A), Color(hex: 0x1B1033), Color(hex: 0x432060)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
