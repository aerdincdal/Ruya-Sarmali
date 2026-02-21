import Foundation

struct DreamInterpretation: Codable {
    let summary: String
    let celestialAdvice: String
    let relationshipInsight: String

    var combined: String {
        "\(summary)\n\nAstro Öneri: \(celestialAdvice)\n\n💕 \(relationshipInsight)"
    }
    
    init(summary: String, celestialAdvice: String, relationshipInsight: String = "Bu rüya, kalbindeki derin duyguları yansıtıyor. Aşk yolda. ✨") {
        self.summary = summary
        self.celestialAdvice = celestialAdvice
        self.relationshipInsight = relationshipInsight
    }
}

struct DreamInterpretationService {
    private let apiKey: String
    private let session: URLSession

    init?(apiKey: String?, session: URLSession = .shared) {
        guard let apiKey, !apiKey.isEmpty else { return nil }
        self.apiKey = apiKey
        self.session = session
    }

    func interpret(prompt: String) async throws -> DreamInterpretation {
        struct RequestPayload: Encodable {
            struct Message: Encodable {
                let role: String
                let content: String
            }
            let model: String
            let messages: [Message]
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

        let systemPrompt = """
        Sen bir astroloji ve sembol uzmanısın. Kullanıcının rüyasını 3 paragrafta yorumla:
        
        1. Rüyanın genel özeti ve sembollerin anlamı.
        2. "Astro Öneri:" başlığıyla astronomik tavsiye.
        3. "💕 İlişki Mesajı:" başlığıyla bu rüyanın aşk ve ilişkiler açısından ne anlama geldiğini romantik ve ilham verici 1-2 cümle ile yaz.
        
        Z kuşağı kadınlarına hitap et, dili sıcak ve mistik tut.
        """
        let payload = RequestPayload(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: prompt)
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "DreamInterpretationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sunucudan yanıt alınamadı"])
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "DreamInterpretationService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw NSError(domain: "DreamInterpretationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI boş içerik gönderdi"])
        }

        // Parse the response
        let components = content.components(separatedBy: "Astro Öneri:")
        let summary = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? content
        
        var advice = "Gökyüzü sezgine güven."
        var relationshipInsight = "Bu rüya, kalbindeki derin duyguları yansıtıyor. Aşkın yolda olduğuna işaret. ✨"
        
        if components.count > 1 {
            let afterAstro = components[1]
            let relationshipParts = afterAstro.components(separatedBy: "💕 İlişki Mesajı:")
            advice = relationshipParts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? advice
            
            if relationshipParts.count > 1 {
                relationshipInsight = relationshipParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return DreamInterpretation(summary: summary, celestialAdvice: advice, relationshipInsight: relationshipInsight)
    }
}
