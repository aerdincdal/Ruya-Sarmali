import SwiftUI

/// Yorum sonucu ekranı - güzel tasarımlı modal sheet
struct InterpretationResultView: View {
    let interpretation: ExtendedInterpretation
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showInstagramStory = false
    @State private var storyImage: UIImage?
    
    private var gradientColors: [Color] {
        interpretation.method.gradient.compactMap { Color(hex: $0) }
    }
    
    /// Metinden markdown yıldızlarını temizle
    private var cleanedInterpretation: String {
        interpretation.mainInterpretation
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "# ", with: "")
    }
    
    private var cleanedRelationship: String {
        interpretation.relationshipInsight
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: 0x0D0B14),
                        Color(hex: 0x1A1030),
                        Color(hex: 0x0D0B14)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        methodHeader
                        mainInterpretationCard
                        relationshipCard
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(interpretation.method.title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [createShareText()], excludedActivityTypes: nil)
            }
            .sheet(isPresented: $showInstagramStory) {
                InterpretationStorySheet(
                    image: storyImage,
                    onShare: shareToInstagram,
                    onSave: saveStoryToPhotos,
                    onDismiss: { showInstagramStory = false }
                )
            }
        }
    }
    
    // MARK: - Method Header
    private var methodHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: gradientColors.first?.opacity(0.5) ?? .clear, radius: 16, x: 0, y: 8)
                
                Image(systemName: interpretation.method.icon)
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(interpretation.method.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text(interpretation.method.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Main Interpretation Card
    private var mainInterpretationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(Color(hex: 0xE6B6FF))
                Text(L10n.yourInterpretation)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(cleanedInterpretation)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Relationship Card
    private var relationshipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text(L10n.relationshipMessage)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(cleanedRelationship)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.pink.opacity(0.15),
                            Color.purple.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Instagram Story Button - Full Width Gradient
            Button(action: {
                AppServices.haptic.medium()
                generateStory()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text(L10n.createInstagramStory)
                        .font(.subheadline.weight(.bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xE1306C), Color(hex: 0xF77737), Color(hex: 0xFCAF45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
            }
            
            // Share and Close buttons
            HStack(spacing: 12) {
                Button(action: { 
                    AppServices.haptic.light()
                    showShareSheet = true 
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.share)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: { 
                    AppServices.haptic.light()
                    dismiss() 
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text(L10n.done)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Story Generation
    private func generateStory() {
        storyImage = InstagramStoryGenerator.generateStoryImage(
            dreamPrompt: "",
            interpretation: cleanedInterpretation,
            relationshipInsight: cleanedRelationship
        )
        showInstagramStory = true
    }
    
    private func shareToInstagram() {
        guard let image = storyImage else { return }
        InstagramStoryGenerator.shareToInstagramStories(image: image)
        showInstagramStory = false
    }
    
    private func saveStoryToPhotos() {
        guard let image = storyImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        AppServices.haptic.success()
        showInstagramStory = false
    }
    
    // MARK: - Share Text
    private func createShareText() -> String {
        """
        \(interpretation.method.title)
        
        \(cleanedInterpretation.prefix(400))...
        
        \(cleanedRelationship)
        
        Ruya Sarmali ile yorumlandi
        """
    }
}

// MARK: - Story Sheet
struct InterpretationStorySheet: View {
    let image: UIImage?
    let onShare: () -> Void
    let onSave: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x0D0B14).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fit)
                            .cornerRadius(20)
                            .shadow(color: .purple.opacity(0.3), radius: 20)
                            .padding(.horizontal, 40)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: onShare) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Instagram'da Paylas")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0xE1306C), Color(hex: 0xF77737)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        
                        Button(action: onSave) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Galeriye Kaydet")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationTitle("Instagram Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { onDismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
