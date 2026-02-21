import SwiftUI

struct DreamHistoryView: View {
    @EnvironmentObject private var repository: DreamRepository
    @EnvironmentObject private var generator: DreamGenerationViewModel
    @State private var selectedVideo: DreamVideo?

    var body: some View {
        ZStack {
            AstroBackgroundView()
            if repository.videos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.7))
                    Text(LocalizationManager.shared.localized("no_videos_yet"))
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(LocalizationManager.shared.localized("start_your_collection"))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .multilineTextAlignment(.center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(repository.videos) { video in
                            Button {
                                AppServices.haptic.light()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    selectedVideo = video
                                }
                            } label: {
                                DreamHistoryRow(video: video)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open video created on \(video.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        }
                    }
                    .padding(20)
                }
            }
        }
        .fullScreenCover(item: $selectedVideo) { video in
            VideoPlaybackView(video: video) {
                selectedVideo = nil
            }
        }
        .navigationTitle(L10n.tabArchive)
    }
}

private struct DreamHistoryRow: View {
    let video: DreamVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(video.prompt)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            if let interpretation = video.interpretation {
                Text(interpretation)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
            Text(video.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(video.previewGradient, in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
