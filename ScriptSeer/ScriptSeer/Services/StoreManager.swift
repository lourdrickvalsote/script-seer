import StoreKit
import Foundation

/// Manages StoreKit 2 subscriptions for ScriptSeer Pro
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    var isProUser: Bool = false
    var monthlyProduct: Product?
    var annualProduct: Product?
    var isLoading: Bool = false
    var errorMessage: String?
    var hasActiveTrialInfo: String?

    private let monthlyProductID = "com.scriptseer.pro.monthly"
    private let annualProductID = "com.scriptseer.pro.annual"

    private init() {
        Task { await loadProducts() }
        Task { await updateSubscriptionStatus() }
        Task { await listenForTransactions() }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [monthlyProductID, annualProductID])
            for product in products {
                if product.id == monthlyProductID {
                    monthlyProduct = product
                } else if product.id == annualProductID {
                    annualProduct = product
                }
            }
        } catch {
            errorMessage = "Failed to load products"
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == monthlyProductID || transaction.productID == annualProductID {
                    let isNotRevoked = transaction.revocationDate == nil
                    let isNotExpired = transaction.expirationDate == nil || transaction.expirationDate! > Date()
                    if isNotRevoked && isNotExpired {
                        hasActiveSubscription = true

                        // Check trial status
                        if let offerType = transaction.offerType, offerType == .introductory {
                            hasActiveTrialInfo = "Free trial active"
                        } else {
                            hasActiveTrialInfo = nil
                        }
                    }
                }
            }
        }

        isProUser = hasActiveSubscription
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
