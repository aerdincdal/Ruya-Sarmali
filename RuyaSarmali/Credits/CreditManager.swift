import Foundation

/// Credit management with secure Keychain storage
@MainActor
final class CreditManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CreditManager()
    
    // MARK: - Credit Package
    struct CreditPackage: Identifiable {
        let productId: String
        let title: String
        let subtitle: String
        let credits: Int
        let fallbackPrice: String
        let highlight: Bool

        var id: String { productId }
        var displayVideoCount: Int { max(1, credits / 2) }
    }

    static let demoLimit = 3
    static let packages: [CreditPackage] = [
        CreditPackage(
            productId: "ruya.credits.spark",
            title: LocalizationManager.shared.currentLanguage == .english ? "Nebula Starter" : "Nebula Başlangıç",
            subtitle: LocalizationManager.shared.currentLanguage == .english ? "10 credits · ~5 videos" : "10 kredi · ~5 üretim",
            credits: 10,
            fallbackPrice: "₺69,99",
            highlight: false
        ),
        CreditPackage(
            productId: "ruya.credits.orbit",
            title: LocalizationManager.shared.currentLanguage == .english ? "Aurora Favorite" : "Aurora Favori",
            subtitle: LocalizationManager.shared.currentLanguage == .english ? "25 credits · ~12 videos" : "25 kredi · ~12 üretim",
            credits: 25,
            fallbackPrice: "₺129,99",
            highlight: true
        ),
        CreditPackage(
            productId: "ruya.credits.infinity",
            title: LocalizationManager.shared.currentLanguage == .english ? "Galaxy Collection" : "Galaksi Koleksiyonu",
            subtitle: LocalizationManager.shared.currentLanguage == .english ? "60 credits · ~30 videos" : "60 kredi · ~30 üretim",
            credits: 60,
            fallbackPrice: "₺249,99",
            highlight: false
        )
    ]

    @Published private(set) var balance: Int
    @Published private(set) var demoRemaining: Int

    let creditCostPerVideo = 2

    private let keychain = KeychainStore()
    private let balanceKey = "ruya_credit_balance"
    private let demoUsageKey = "ruya_demo_usage_count"

    private init() {
        // Load balance from Keychain (secure storage that persists across reinstalls)
        balance = keychain.int(forKey: balanceKey) ?? 0
        let usage = keychain.int(forKey: demoUsageKey) ?? 0
        demoRemaining = max(0, CreditManager.demoLimit - usage)
    }

    var hasCredits: Bool { balance >= creditCostPerVideo || demoRemaining >= creditCostPerVideo }

    func consumeCredit(cost: Int) -> Bool {
        // First try to use purchased credits
        if balance >= cost {
            balance -= cost
            keychain.setInt(balance, forKey: balanceKey)
            return true
        }
        // Then try demo credits
        if demoRemaining >= cost {
            let currentUsage = keychain.int(forKey: demoUsageKey) ?? 0
            let newUsage = currentUsage + cost
            keychain.setInt(newUsage, forKey: demoUsageKey)
            demoRemaining = max(0, CreditManager.demoLimit - newUsage)
            return true
        }
        return false
    }

    func refundCredits(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
        keychain.setInt(balance, forKey: balanceKey)
    }

    func addCredits(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
        keychain.setInt(balance, forKey: balanceKey)
    }

    func demoLabel() -> String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        if demoRemaining > 0 {
            return isEnglish 
                ? "Free trials: \(demoRemaining)/\(CreditManager.demoLimit)" 
                : "Demo hakkın: \(demoRemaining)/\(CreditManager.demoLimit)"
        } else {
            return isEnglish 
                ? "Free trials used" 
                : "Demo hakların tükendi"
        }
    }
}
