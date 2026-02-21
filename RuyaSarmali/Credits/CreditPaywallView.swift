import SwiftUI

struct CreditPaywallView: View {
    @EnvironmentObject private var creditManager: CreditManager
    @EnvironmentObject private var creditStore: CreditStore
    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false
    @State private var isRestoring = false
    @State private var alertMessage: String?
    @State private var alertTitle: String = ""

    private var isEnglish: Bool { LocalizationManager.shared.currentLanguage == .english }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: 0xE6B6FF), Color(hex: 0xC28BFF)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(L10n.boostCredits)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(L10n.creditPackagesSubtitle)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Loading indicator
                    if creditStore.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    }

                    // Package cards
                    ForEach(creditStore.packages) { package in
                        packageCard(package)
                    }

                    // Restore Purchases (App Store Requirement)
                    Button(action: restorePurchases) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(isEnglish ? "Restore Purchases" : "Satın Almaları Geri Yükle")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .disabled(isRestoring)
                    .padding(.top, 8)

                    Text(L10n.purchaseSecurity)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
            .background(AstroBackgroundView())
            .navigationTitle(L10n.creditPackagesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert(alertTitle, isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button(L10n.done, role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func packageCard(_ package: CreditManager.CreditPackage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if package.highlight {
                            Text(L10n.mostPopular)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: 0xE6B6FF), Color(hex: 0xC28BFF)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .foregroundColor(.black)
                        }
                    }
                    
                    Text(package.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(creditStore.displayPrice(for: package))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            Button {
                purchase(package)
            } label: {
                HStack {
                    if isProcessing && creditStore.purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(isProcessing ? L10n.processing : L10n.purchase)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(
                LinearGradient(
                    colors: package.highlight 
                        ? [Color(hex: 0x9B6BC3), Color(hex: 0x6B4FA2)]
                        : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundColor(.white)
            .disabled(isProcessing)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: package.highlight 
                            ? [Color(hex: 0x3A1D58), Color(hex: 0x2A1545)]
                            : [Color(hex: 0x1A1030), Color(hex: 0x241540)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            package.highlight 
                                ? Color(hex: 0xC28BFF).opacity(0.4) 
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)
        )
    }

    private func purchase(_ package: CreditManager.CreditPackage) {
        Task {
            isProcessing = true
            AppServices.haptic.medium()
            
            do {
                try await creditStore.purchase(package, creditManager: creditManager)
                alertTitle = isEnglish ? "Success!" : "Başarılı!"
                alertMessage = String(format: L10n.creditsAdded, package.credits)
                AppServices.haptic.success()
            } catch CreditStore.PurchaseError.cancelled {
                // User cancelled, no alert needed
            } catch {
                alertTitle = L10n.error
                alertMessage = error.localizedDescription
                AppServices.haptic.error()
            }
            
            isProcessing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            isRestoring = true
            AppServices.haptic.light()
            
            do {
                try await creditStore.restorePurchases(creditManager: creditManager)
                alertTitle = isEnglish ? "Restored" : "Geri Yüklendi"
                alertMessage = isEnglish 
                    ? "Your purchases have been restored." 
                    : "Satın almalarınız geri yüklendi."
                AppServices.haptic.success()
            } catch {
                alertTitle = L10n.error
                alertMessage = error.localizedDescription
                AppServices.haptic.error()
            }
            
            isRestoring = false
        }
    }
}
