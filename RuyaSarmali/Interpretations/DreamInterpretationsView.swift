import SwiftUI

/// Ana Rüya Tabirleri ekranı - 6 farklı yorum metodunu sunar
struct DreamInterpretationsView: View {
    @State private var selectedMethod: InterpretationMethod?
    @State private var dreamText: String = ""
    @State private var isInterpreting: Bool = false
    @State private var currentInterpretation: ExtendedInterpretation?
    @State private var showResult: Bool = false
    @EnvironmentObject private var generator: DreamGenerationViewModel
    
    var body: some View {
        ZStack {
            AstroBackgroundView()
                .onTapGesture {
                    dismissKeyboard()
                }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    
                    if generator.prompt.isEmpty {
                        dreamInputSection
                    } else {
                        currentDreamPreview
                    }
                    
                    methodsGrid
                    
                    if isInterpreting {
                        interpretingAnimation
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(L10n.interpretationsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResult) {
            if let interpretation = currentInterpretation {
                InterpretationResultView(interpretation: interpretation)
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: 0xE6B6FF))
                Text(L10n.interpretDream)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            }
            
            Text(L10n.interpretationsSubtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Dream Input
    private var dreamInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.writeDream, systemImage: "pencil.line")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $dreamText)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .font(.body)
                .frame(minHeight: 120)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            
            Text("\(dreamText.split { $0.isWhitespace }.count) kelime")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }
    
    // MARK: - Current Dream Preview
    private var currentDreamPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(Color(hex: 0xC28BFF))
                Text(L10n.currentDream)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Değiştir") {
                    dreamText = generator.prompt
                }
                .font(.caption)
                .foregroundColor(Color(hex: 0xE6B6FF))
            }
            
            Text(generator.prompt)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x2A1B47), Color(hex: 0x1A1030)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC28BFF).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Methods Grid
    private var methodsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.selectMethod)
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(InterpretationMethod.allCases) { method in
                    InterpretationMethodCard(
                        method: method,
                        isSelected: selectedMethod == method,
                        isLoading: isInterpreting && selectedMethod == method
                    ) {
                        selectMethod(method)
                    }
                }
            }
        }
    }
    
    // MARK: - Interpreting Animation
    private var interpretingAnimation: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: 0xE6B6FF))
            
            Text(L10n.interpreting)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
        )
    }
    
    // MARK: - Actions
    private func selectMethod(_ method: InterpretationMethod) {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        let prompt = dreamText.isEmpty ? generator.prompt : dreamText
        guard prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else {
            return
        }
        
        selectedMethod = method
        isInterpreting = true
        
        Task {
            await performInterpretation(prompt: prompt, method: method)
        }
    }
    
    private func performInterpretation(prompt: String, method: InterpretationMethod) async {
        // Get API key
        guard let apiKey = Secrets.value(for: .openAIKey) else {
            isInterpreting = false
            return
        }
        
        do {
            let interpretation = try await InterpretationService.shared.interpret(
                prompt: prompt,
                method: method,
                apiKey: apiKey
            )
            
            await MainActor.run {
                currentInterpretation = interpretation
                isInterpreting = false
                showResult = true
            }
        } catch {
            await MainActor.run {
                isInterpreting = false
                print("Interpretation error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Interpretation Service
class InterpretationService {
    static let shared = InterpretationService()
    private init() {}
    
    func interpret(prompt: String, method: InterpretationMethod, apiKey: String) async throws -> ExtendedInterpretation {
        let fullSystemPrompt = method.systemPrompt + method.relationshipPromptAddition
        
        struct RequestPayload: Encodable {
            struct Message: Encodable {
                let role: String
                let content: String
            }
            let model: String
            let messages: [Message]
            let max_tokens: Int
        }
        
        struct ResponsePayload: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        let payload = RequestPayload(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "system", content: fullSystemPrompt),
                .init(role: "user", content: "Rüyam: \(prompt)")
            ],
            max_tokens: 1000
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "InterpretationService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        let decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw NSError(domain: "InterpretationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Boş yanıt"])
        }
        
        // Parse relationship insight - try both formats
        var mainInterpretation = content
        var relationshipInsight = "Bu ruya, kalbindeki derin duygulari yansitiyor. Askin yolda olduguna isaret."
        
        // Try parsing with "Iliski Mesaji:" first
        if content.contains("Iliski Mesaji:") {
            let components = content.components(separatedBy: "Iliski Mesaji:")
            mainInterpretation = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? content
            if components.count > 1 {
                relationshipInsight = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return ExtendedInterpretation(
            method: method,
            mainInterpretation: mainInterpretation,
            relationshipInsight: relationshipInsight
        )
    }
}
