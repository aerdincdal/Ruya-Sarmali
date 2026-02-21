import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum SocialShareTarget: String, Identifiable {
    case system
    case instagram
    case tiktok

    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "Paylaş"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        }
    }

    var icon: String {
        switch self {
        case .system: return "square.and.arrow.up"
        case .instagram: return "camera"
        case .tiktok: return "music.note"
        }
    }

    var tint: Color {
        switch self {
        case .system: return .white
        case .instagram: return Color(hex: 0xFE2D6C)
        case .tiktok: return Color(hex: 0x29D1EA)
        }
    }
}
