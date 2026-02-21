import SwiftUI
import AVKit

struct VideoPlaybackView: View {
    let video: DreamVideo
    let onClose: () -> Void

    @EnvironmentObject private var repository: DreamRepository
    @EnvironmentObject private var generationViewModel: DreamGenerationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var player = AVPlayer()
    @State private var activeShareTarget: SocialShareTarget?
    @State private var saveResult: SaveResult?
    @State private var showFullInterpretation = false
    @State private var showInstagramStory = false
    @State private var storyImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Video Player
                    ZStack(alignment: .topLeading) {
                        VideoPlayer(player: player)
                            .onAppear { preparePlayer() }
                            .onDisappear { player.pause() }
                            .accessibilityLabel("Dream video playback")
                            .cornerRadius(20)
                            .frame(height: UIScreen.main.bounds.height * 0.45)

                        Button(action: close) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4), in: Circle())
                        }
                        .padding(16)
                    }

                    // Dream info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(video.prompt)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(video.createdAt, style: .date)
                            .foregroundColor(.white.opacity(0.6))
                            .font(.subheadline)
                        
                        // Interpretation with expand
                        if let interpretation = video.interpretation {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(interpretation)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(showFullInterpretation ? nil : 4)
                                    .animation(.easeInOut, value: showFullInterpretation)
                                
                                if interpretation.count > 200 {
                                    Button(action: { 
                                        withAnimation { showFullInterpretation.toggle() }
                                        AppServices.haptic.light()
                                    }) {
                                        HStack {
                                            Text(showFullInterpretation ? L10n.showLess : L10n.showMore)
                                                .font(.caption.weight(.semibold))
                                            Image(systemName: showFullInterpretation ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundColor(Color(hex: 0xE6B6FF))
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            playbackButton(title: L10n.save, icon: "square.and.arrow.down", tint: .white) {
                                AppServices.haptic.medium()
                                Task {
                                    do {
                                        try await generationViewModel.saveToPhotos()
                                        saveResult = .success
                                        AppServices.haptic.success()
                                    } catch {
                                        saveResult = .failure(error.localizedDescription)
                                        AppServices.haptic.error()
                                    }
                                }
                            }

                            playbackButton(title: L10n.share, icon: "square.and.arrow.up", tint: .white) {
                                AppServices.haptic.medium()
                                activeShareTarget = .system
                            }
                        }
                        
                        // Instagram Story Button
                        Button(action: { 
                            AppServices.haptic.medium()
                            generateAndShowStory() 
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                Text(L10n.createInstagramStory)
                                    .font(.subheadline.weight(.semibold))
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
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $activeShareTarget) { _ in
            let url = repository.url(for: video)
            let shareText = """
            \(video.prompt)
            
            \(video.interpretation ?? "")
            
            Ruya Sarmali ile olusturuldu
            Uygulama: https://apps.apple.com/app/ruya-sarmali
            """
            ShareSheet(activityItems: [shareText, url], excludedActivityTypes: nil)
        }
        .sheet(isPresented: $showInstagramStory) {
            InstagramStorySheet(
                image: storyImage,
                onShare: shareToInstagram,
                onSave: saveStoryToPhotos
            )
        }
        .alert(item: $saveResult) { result in
            switch result {
            case .success:
                return Alert(title: Text("Kaydedildi"), message: Text("Video galeriye kaydedildi."), dismissButton: .default(Text("Tamam")))
            case .failure(let error):
                return Alert(title: Text("Hata"), message: Text(error), dismissButton: .default(Text("Tamam")))
            }
        }
    }

    private func preparePlayer() {
        let url = repository.url(for: video)
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
    }

    private func close() {
        player.pause()
        onClose()
        dismiss()
    }
    
    private func generateAndShowStory() {
        storyImage = InstagramStoryGenerator.generateStoryImage(
            dreamPrompt: video.prompt,
            interpretation: video.interpretation ?? "",
            relationshipInsight: "Bu ruya ozel bir anlam tasiyor."
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
        saveResult = .success
        showInstagramStory = false
    }

    private func playbackButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
        }
        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 20, tint: tint))
        .contentShape(Rectangle())
    }
}

// MARK: - Instagram Story Sheet
struct InstagramStorySheet: View {
    let image: UIImage?
    let onShare: () -> Void
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
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
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

private enum SaveResult: Identifiable {
    case success
    case failure(String)

    var id: String {
        switch self {
        case .success: return "success"
        case .failure(let message): return "failure_\(message)"
        }
    }
}
