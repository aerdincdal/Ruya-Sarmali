import SwiftUI
import UIKit

/// Instagram Stories icin paylasim gorseli olusturur
struct InstagramStoryGenerator {
    
    /// Ruya yorumunu Instagram story formatinda gorsel olarak olusturur
    static func generateStoryImage(
        dreamPrompt: String,
        interpretation: String,
        relationshipInsight: String,
        method: String = "Astrolojik"
    ) -> UIImage? {
        let size = CGSize(width: 1080, height: 1920) // 9:16 aspect ratio
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background gradient
            let gradientColors = [
                UIColor(red: 0.05, green: 0.03, blue: 0.08, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.06, blue: 0.19, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.03, blue: 0.08, alpha: 1).cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0, 0.5, 1]
            )!
            
            ctx.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
            
            // Decorative stars
            drawStars(in: ctx, size: size)
            
            // Content card
            let cardRect = CGRect(x: 60, y: 400, width: size.width - 120, height: 1000)
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 48)
            ctx.addPath(cardPath.cgPath)
            ctx.fillPath()
            
            // Card border
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            ctx.setLineWidth(2)
            ctx.addPath(cardPath.cgPath)
            ctx.strokePath()
            
            // Method badge
            let badgeRect = CGRect(x: cardRect.midX - 80, y: cardRect.minY + 40, width: 160, height: 40)
            ctx.setFillColor(UIColor(red: 0.42, green: 0.31, blue: 0.64, alpha: 0.8).cgColor)
            let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 20)
            ctx.addPath(badgePath.cgPath)
            ctx.fillPath()
            
            // Method text
            let methodAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let methodText = method as NSString
            let methodSize = methodText.size(withAttributes: methodAttr)
            methodText.draw(
                at: CGPoint(
                    x: badgeRect.midX - methodSize.width / 2,
                    y: badgeRect.midY - methodSize.height / 2
                ),
                withAttributes: methodAttr
            )
            
            // Moon icon placeholder
            let moonRect = CGRect(x: cardRect.midX - 40, y: cardRect.minY + 100, width: 80, height: 80)
            ctx.setFillColor(UIColor(red: 0.90, green: 0.71, blue: 1, alpha: 1).cgColor)
            ctx.fillEllipse(in: moonRect)
            
            // Dream prompt
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleRect = CGRect(x: cardRect.minX + 40, y: cardRect.minY + 220, width: cardRect.width - 80, height: 150)
            let promptParagraph = NSMutableParagraphStyle()
            promptParagraph.alignment = .center
            promptParagraph.lineSpacing = 8
            
            let promptAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: promptParagraph
            ]
            
            let truncatedPrompt = String(dreamPrompt.prefix(100)) + (dreamPrompt.count > 100 ? "..." : "")
            (truncatedPrompt as NSString).draw(in: titleRect, withAttributes: promptAttr)
            
            // Interpretation
            let interpParagraph = NSMutableParagraphStyle()
            interpParagraph.alignment = .left
            interpParagraph.lineSpacing = 6
            
            let interpAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: interpParagraph
            ]
            
            let interpRect = CGRect(x: cardRect.minX + 40, y: cardRect.minY + 380, width: cardRect.width - 80, height: 300)
            let truncatedInterp = String(interpretation.prefix(300)) + (interpretation.count > 300 ? "..." : "")
            (truncatedInterp as NSString).draw(in: interpRect, withAttributes: interpAttr)
            
            // Relationship insight card
            let heartRect = CGRect(x: cardRect.minX + 40, y: cardRect.minY + 720, width: cardRect.width - 80, height: 180)
            ctx.setFillColor(UIColor(red: 1, green: 0.4, blue: 0.6, alpha: 0.2).cgColor)
            let heartPath = UIBezierPath(roundedRect: heartRect, cornerRadius: 24)
            ctx.addPath(heartPath.cgPath)
            ctx.fillPath()
            
            // Heart icon
            let heartIconAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor(red: 1, green: 0.4, blue: 0.6, alpha: 1)
            ]
            ("Iliski Mesaji" as NSString).draw(
                at: CGPoint(x: heartRect.minX + 20, y: heartRect.minY + 20),
                withAttributes: heartIconAttr
            )
            
            let relationAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: interpParagraph
            ]
            let relationRect = CGRect(x: heartRect.minX + 20, y: heartRect.minY + 60, width: heartRect.width - 40, height: 100)
            (relationshipInsight as NSString).draw(in: relationRect, withAttributes: relationAttr)
            
            // App branding at bottom
            let brandAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            let brandText = "Ruya Sarmali" as NSString
            let brandSize = brandText.size(withAttributes: brandAttr)
            brandText.draw(
                at: CGPoint(x: size.width / 2 - brandSize.width / 2, y: size.height - 150),
                withAttributes: brandAttr
            )
            
            let subtitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]
            let subtitleText = "Ruyalarini filme donustur" as NSString
            let subtitleSize = subtitleText.size(withAttributes: subtitleAttr)
            subtitleText.draw(
                at: CGPoint(x: size.width / 2 - subtitleSize.width / 2, y: size.height - 110),
                withAttributes: subtitleAttr
            )
        }
    }
    
    private static func drawStars(in context: CGContext, size: CGSize) {
        let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
            (0.1, 0.15, 3),
            (0.85, 0.1, 4),
            (0.2, 0.25, 2),
            (0.9, 0.3, 3),
            (0.15, 0.85, 3),
            (0.8, 0.9, 4),
            (0.5, 0.05, 5),
            (0.3, 0.95, 2)
        ]
        
        for (xRatio, yRatio, radius) in starPositions {
            let x = size.width * xRatio
            let y = size.height * yRatio
            
            context.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }
    
    /// Gorseli Instagram Stories'a paylas
    static func shareToInstagramStories(image: UIImage) {
        guard let imageData = image.pngData() else { return }
        
        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]
        
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        
        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
        
        if let url = URL(string: "instagram-stories://share") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - SwiftUI Story Preview Card
struct StoryPreviewCard: View {
    let dreamPrompt: String
    let interpretation: String
    let relationshipInsight: String
    
    @State private var storyImage: UIImage?
    @State private var showShareOptions = false
    
    var body: some View {
        VStack(spacing: 16) {
            if let image = storyImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(9/16, contentMode: .fit)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .aspectRatio(9/16, contentMode: .fit)
                    .cornerRadius(20)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
            
            HStack(spacing: 16) {
                Button(action: shareToInstagram) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Instagram")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 16, tint: Color(hex: 0xE1306C)))
                
                Button(action: saveToPhotos) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Kaydet")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 16))
            }
        }
        .onAppear {
            generateImage()
        }
    }
    
    private func generateImage() {
        storyImage = InstagramStoryGenerator.generateStoryImage(
            dreamPrompt: dreamPrompt,
            interpretation: interpretation,
            relationshipInsight: relationshipInsight
        )
    }
    
    private func shareToInstagram() {
        guard let image = storyImage else { return }
        InstagramStoryGenerator.shareToInstagramStories(image: image)
    }
    
    private func saveToPhotos() {
        guard let image = storyImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
