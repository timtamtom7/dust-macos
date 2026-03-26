import Foundation
import StoreKit

// MARK: - Subscription Manager (R16)

@MainActor
final class DustSubscriptionManager: ObservableObject {
    static let shared = DustSubscriptionManager()

    @Published private(set) var currentTier: DustSubscriptionTier = .free
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var purchaseError: String?
    @Published var hasActiveSubscription: Bool = false

    private var transactionListener: Task<Void, Error>?
    private let userDefaultsKey = "dust_subscription_tier"

    private init() {
        loadCurrentTier()
        startTransactionListener()
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = [
                "com.dust.pro.monthly", "com.dust.pro.yearly",
                "com.dust.team.monthly", "com.dust.team.yearly"
            ]
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ tier: DustSubscriptionTier, period: String = "monthly") async throws -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let productId = tier.productId + "." + period
        guard let product = products.first(where: { $0.id == productId }) else {
            purchaseError = "Product not found"
            return false
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCurrentTier(tier)
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            purchaseError = "Purchase is pending"
            return false
        default:
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await updateTierFromTransactions()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func startTransactionListener() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateTierFromTransactions()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func updateTierFromTransactions() async {
        var highestTier: DustSubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let productId = transaction.productID as String? {
                    if productId.contains("pro") && DustSubscriptionTier.pro.rawValue > highestTier.rawValue { highestTier = .pro }
                    if productId.contains("team") && DustSubscriptionTier.team.rawValue > highestTier.rawValue { highestTier = .team }
                }
            }
        }
        await updateCurrentTier(highestTier)
    }

    private func updateCurrentTier(_ tier: DustSubscriptionTier) async {
        currentTier = tier
        hasActiveSubscription = tier != .free
        UserDefaults.standard.set(currentTier.rawValue, forKey: userDefaultsKey)
    }

    private func loadCurrentTier() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let tier = DustSubscriptionTier(rawValue: saved) {
            currentTier = tier
            hasActiveSubscription = tier != .free
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.verificationFailed
        case .verified(let value): return value
        }
    }

    func hasEntitlement(_ feature: String) -> Bool {
        switch currentTier {
        case .free: return false
        case .pro: return true
        case .team: return true
        }
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    var errorDescription: String? { "Transaction verification failed" }
}

// Extension to add productId to existing DustSubscriptionTier
extension DustSubscriptionTier {
    var productId: String {
        switch self {
        case .free: return "com.dust.free"
        case .pro: return "com.dust.pro"
        case .team: return "com.dust.team"
        }
    }
}
