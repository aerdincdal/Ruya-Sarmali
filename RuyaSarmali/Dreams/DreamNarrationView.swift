import SwiftUI
import AVKit

struct DreamNarrationView: View {
    @EnvironmentObject private var viewModel: DreamGenerationViewModel
    @EnvironmentObject private var creditManager: CreditManager
    @State private var showPaywall = false
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        ZStack {
            AstroBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Compact credit badge at top
                    creditBadge
                    
                    // Beautiful dream input area
                    dreamInputCard
                    
                    // Action button
                    generateButton
                    
                    // Generation progress
                    if viewModel.isGenerating {
                        GenerationVisualizer(progress: viewModel.progress, message: viewModel.progressMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .onTapGesture {
                isPromptFocused = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            CreditPaywallView()
        }
        .sheet(isPresented: $viewModel.showInterpretationSheet) {
            AstroInterpretationSheet(interpretation: viewModel.astroInterpretation)
        }
        .fullScreenCover(item: Binding(
            get: { viewModel.currentVideo },
            set: { viewModel.currentVideo = $0 }
        )) { video in
            VideoPlaybackView(video: video) {
                viewModel.discardCurrentVideo()
            }
            .environmentObject(viewModel)
        }
        .alert(L10n.error, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L10n.close, role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Credit Badge (Compact, Top)
    private var creditBadge: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 12) {
                // Sparkle icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: 0x9B6BC3), Color(hex: 0xE6B6FF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("\(creditManager.balance)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(L10n.credits)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text(creditManager.demoLabel())
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Add credits button
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.buyCredits)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: 0xE6B6FF))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().stroke(Color(hex: 0xE6B6FF).opacity(0.3), lineWidth: 1))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Dream Input Card (Main Focus)
    private var dreamInputCard: some View {
        VStack(spacing: 0) {
            // Floating title
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xC28BFF), Color(hex: 0xE6B6FF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(LocalizationManager.shared.currentLanguage == .english ? "What did you dream?" : "Ne rüya gördün?")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                if viewModel.prompt.isEmpty {
                    Text(LocalizationManager.shared.currentLanguage == .english 
                        ? "Describe your dream in detail...\n\nExample: I was walking through a purple forest when a glowing cat appeared and led me to a hidden crystal cave..." 
                        : "Rüyanızı detaylıca anlatın...\n\nÖrnek: Mor bir ormanın içinde yürüyordum, parıldayan bir kedi belirdi ve beni gizli bir kristal mağaraya götürdü...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
                
                TextEditor(text: $viewModel.prompt)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .font(.body)
                    .focused($isPromptFocused)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 200)
            }
            
            // Word counter
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "text.word.spacing")
                        .font(.caption2)
                    Text("\(viewModel.prompt.split { $0.isWhitespace }.count)")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A1030).opacity(0.9), Color(hex: 0x2A1B47).opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: 0xC28BFF).opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(hex: 0x9B6BC3).opacity(0.2), radius: 30, y: 20)
        )
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: startGeneration) {
            HStack(spacing: 14) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    if viewModel.isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isGenerating 
                        ? (LocalizationManager.shared.currentLanguage == .english ? "Creating Your Dream..." : "Rüyan Oluşturuluyor...")
                        : (LocalizationManager.shared.currentLanguage == .english ? "Bring My Dream to Life ✨" : "Rüyamı Hayata Geçir ✨"))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    
                    if !viewModel.isGenerating {
                        Text(LocalizationManager.shared.currentLanguage == .english 
                            ? "Transform into cinematic video" 
                            : "Sinematik videoya dönüştür")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if !viewModel.isGenerating {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: viewModel.isGenerating 
                        ? [Color(hex: 0x4A3A6A), Color(hex: 0x3A2A5A)]
                        : [Color(hex: 0x6B4FA2), Color(hex: 0x9B6BC3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x6B4FA2).opacity(0.4), radius: 20, y: 10)
        }
        .disabled(viewModel.isGenerating || viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
        .opacity(viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 || viewModel.isGenerating ? 1 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isGenerating)
    }

    private func startGeneration() {
        isPromptFocused = false
        
        if creditManager.hasCredits {
            AppServices.haptic.medium()
            viewModel.generateVideo()
        } else {
            showPaywall = true
        }
    }
}

struct GlassSurface: View {
    let cornerRadius: CGFloat
    let gradient: Gradient

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.85))
            .background(
                LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.45)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

struct GenerationVisualizer: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(LocalizationManager.shared.currentLanguage == .english ? "Creating Video" : "Video Oluşturuluyor")
                .font(.headline)
                .foregroundColor(.white)
            ZStack {
                LiquidOrbitalAnimation(progress: progress)
                    .frame(height: 240)
                VStack(spacing: 8) {
                    Text(ProgressFormatter.percent(progress))
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(message.isEmpty ? L10n.dreamBecomingVideo : message)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(28)
        .background(GlassSurface(cornerRadius: 32, gradient: Gradient(colors: [Color(hex: 0x1A1037), Color(hex: 0x2E1F52)])))
    }
}

struct LiquidOrbitalAnimation: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 12
                for orbit in 0..<5 {
                    let path = Path { path in
                        path.addArc(center: center, radius: radius - CGFloat(orbit) * 20, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                    }
                    let alpha = 0.2 + Double(orbit) * 0.08
                    context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 0.8)
                    let angle = CGFloat(time * Double(orbit + 1) * 0.6)
                    let dotCenter = CGPoint(x: center.x + cos(angle) * (radius - CGFloat(orbit) * 20), y: center.y + sin(angle) * (radius - CGFloat(orbit) * 20))
                    let dotRect = CGRect(x: dotCenter.x - 4, y: dotCenter.y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: dotRect), with: .color(Color.purple.opacity(0.8)))
                }

                let cometRadius = radius * CGFloat(progress)
                let cometPath = Path { path in
                    path.addArc(center: center, radius: cometRadius, startAngle: .degrees(-90), endAngle: .degrees(Double(progress) * 360 - 90), clockwise: false)
                }
                context.stroke(cometPath, with: .color(Color.cyan.opacity(0.9)), lineWidth: 3)
            }
        }
    }
}

struct AstroInterpretationSheet: View {
    let interpretation: DreamInterpretation?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let interpretation = interpretation {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(L10n.dreamSummary)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Text(interpretation.summary)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            Text(LocalizationManager.shared.currentLanguage == .english ? "✨ Astrological Interpretation" : "✨ Astrolojik Yorum")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Text(interpretation.celestialAdvice)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.purple.opacity(0.6))
                            Text(LocalizationManager.shared.currentLanguage == .english ? "No interpretation yet" : "Henüz yorum yok")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            Text(LocalizationManager.shared.currentLanguage == .english 
                                ? "Write your dream and tap the button to see the astrological interpretation." 
                                : "Rüyanı yazdıktan sonra astrolojik yorumunu görmek için butona dokun.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(24)
                .background(GlassSurface(cornerRadius: 32, gradient: Gradient(colors: [Color(hex: 0x241138), Color(hex: 0x3A1D58)])))
                .padding()
            }
            .background(Color.black.opacity(0.6).ignoresSafeArea())
            .navigationTitle(LocalizationManager.shared.currentLanguage == .english ? "Astrological Interpretation" : "Astrolojik Yorum")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
    }
}

enum ProgressFormatter {
    static func percent(_ value: Double) -> String {
        let sanitized = min(max(value, 0), 1)
        return "\(Int(sanitized * 100))%"
    }
}
