import Foundation
import StoreKit

@available(macOS 13.0, *)
public final class DustSubscriptionManager: ObservableObject {
    public static let shared = DustSubscriptionManager()
    @Published public private(set) var subscription: DustSubscription?
    @Published public private(set) var products: [Product] = []
    private init() {}
    public func loadProducts() async {
        do { products = try await Product.products(for: ["com.dust.macos.pro.monthly","com.dust.macos.pro.yearly","com.dust.macos.team.monthly","com.dust.macos.team.yearly"]) }
        catch { print("Failed to load products") }
    }
    public func canAccess(_ feature: DustFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .team: return sub.tier == .team
        }
    }
    public func updateStatus() async {
        var found: DustSubscription = DustSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("team") { found = DustSubscription(tier: .team, status: t.revocationDate == nil ? "active" : "expired") }
                else if t.productID.contains("pro") { found = DustSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired") }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    public func restore() async throws { try await AppStore.sync(); await updateStatus() }
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T { switch r { case .unverified: throw NSError(domain: "Dust", code: -1); case .verified(let s): return s } }
}
public enum DustFeature { case widgets, shortcuts, team }
