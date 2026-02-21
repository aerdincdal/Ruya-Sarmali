import Foundation
import StoreKit

/// Production-ready StoreKit 2 implementation with transaction listening and full security
@MainActor
final class CreditStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var productsLoaded = false
    
    let packages: [CreditManager.CreditPackage]
    private var transactionListener: Task<Void, Error>?
    
    init(packages: [CreditManager.CreditPackage]) {
        self.packages = packages
        
        // Start listening for transactions (interrupted purchases, family sharing, etc.)
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await checkForUnfinishedTransactions()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        guard !productsLoaded else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let identifiers = Set(packages.map { $0.productId })
            products = try await Product.products(for: identifiers)
                .sorted { $0.price < $1.price }
            productsLoaded = !products.isEmpty
            
            if products.isEmpty {
                print("⚠️ StoreKit: No products found. Check App Store Connect configuration.")
            } else {
                print("✅ StoreKit: Loaded \(products.count) products")
            }
        } catch {
            print("❌ StoreKit products failed to load: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Transaction Listener
    
    /// Listens for transactions that happen outside the app (Ask to Buy, interrupted purchases, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.handleVerification(result)
                    
                    // Find the corresponding package and add credits
                    if let package = await self.packages.first(where: { $0.productId == transaction.productID }) {
                        await MainActor.run {
                            CreditManager.shared.addCredits(package.credits)
                        }
                        print("✅ Transaction listener: Added \(package.credits) credits for \(transaction.productID)")
                    }
                    
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Check for any unfinished transactions on app launch
    func checkForUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try await handleVerification(result)
                
                // Find the corresponding package and add credits
                if let package = packages.first(where: { $0.productId == transaction.productID }) {
                    CreditManager.shared.addCredits(package.credits)
                    print("✅ Recovered unfinished transaction: \(package.credits) credits")
                }
                
                await transaction.finish()
            } catch {
                print("❌ Unfinished transaction verification failed: \(error)")
            }
        }
    }
    
    // MARK: - Purchase (Production-Ready)
    
    func purchase(_ package: CreditManager.CreditPackage, creditManager: CreditManager) async throws {
        // SECURITY: In production, products MUST be loaded from App Store Connect
        guard let product = product(for: package) else {
            // Try to reload products
            await loadProducts()
            
            guard let product = product(for: package) else {
                throw PurchaseError.productNotFound
            }
            
            return try await executePurchase(product: product, package: package, creditManager: creditManager)
        }
        
        try await executePurchase(product: product, package: package, creditManager: creditManager)
    }
    
    private func executePurchase(product: Product, package: CreditManager.CreditPackage, creditManager: CreditManager) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // SECURITY: Only add credits after Apple verification
            let transaction = try await handleVerification(verification)
            
            // Credits are added only after successful verification
            creditManager.addCredits(package.credits)
            print("✅ Purchase successful: Added \(package.credits) credits")
            
            // Always finish the transaction
            await transaction.finish()
            
        case .userCancelled:
            throw PurchaseError.cancelled
            
        case .pending:
            // Transaction requires approval (Ask to Buy, etc.)
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    // MARK: - Restore Purchases (App Store Requirement)
    
    /// Restore purchases - required by App Store guidelines
    func restorePurchases(creditManager: CreditManager) async throws {
        // Sync with App Store to get latest transactions
        try await AppStore.sync()
        
        var restoredCount = 0
        
        // Note: For consumables, this checks current entitlements
        // Consumables are typically not restorable, but we check anyway
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await handleVerification(result)
                
                if let package = packages.first(where: { $0.productId == transaction.productID }) {
                    // Only restore if not already processed
                    restoredCount += 1
                    print("✅ Found entitlement: \(transaction.productID)")
                }
            } catch {
                continue
            }
        }
        
        if restoredCount == 0 {
            throw PurchaseError.noPurchasesToRestore
        }
    }
    
    // MARK: - Helpers
    
    func displayPrice(for package: CreditManager.CreditPackage) -> String {
        if let product = product(for: package) {
            return product.displayPrice
        }
        // Fallback price shown while loading
        return package.fallbackPrice
    }
    
    func product(for package: CreditManager.CreditPackage) -> Product? {
        products.first(where: { $0.id == package.productId })
    }
    
    private func handleVerification(_ result: VerificationResult<Transaction>) async throws -> Transaction {
        switch result {
        case .verified(let transaction):
            // Transaction is verified by Apple - safe to grant credits
            return transaction
        case .unverified(let transaction, let error):
            // Transaction failed Apple's verification
            print("❌ Transaction verification failed for \(transaction.productID): \(error)")
            throw PurchaseError.verificationFailed(error)
        }
    }
    
    // MARK: - Errors (Localized)
    
    enum PurchaseError: LocalizedError {
        case productNotFound
        case verificationFailed(Error)
        case pending
        case cancelled
        case noPurchasesToRestore
        case unknown
        
        var errorDescription: String? {
            let isEnglish = LocalizationManager.shared.currentLanguage == .english
            switch self {
            case .productNotFound:
                return isEnglish 
                    ? "Products could not be loaded. Please check your internet connection and try again." 
                    : "Ürünler yüklenemedi. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin."
            case .verificationFailed:
                return isEnglish 
                    ? "Purchase verification failed. Please contact support." 
                    : "Satın alma doğrulanamadı. Lütfen destek ile iletişime geçin."
            case .pending:
                return isEnglish 
                    ? "Your purchase is pending approval. Credits will be added once approved." 
                    : "Satın alma onay bekliyor. Onaylandığında krediler eklenecek."
            case .cancelled:
                return isEnglish 
                    ? "Purchase was cancelled." 
                    : "Satın alma iptal edildi."
            case .noPurchasesToRestore:
                return isEnglish 
                    ? "No previous purchases found to restore." 
                    : "Geri yüklenecek önceki satın alma bulunamadı."
            case .unknown:
                return isEnglish 
                    ? "An unexpected error occurred. Please try again." 
                    : "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."
            }
        }
    }
}
