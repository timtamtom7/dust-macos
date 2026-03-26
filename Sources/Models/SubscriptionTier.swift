import Foundation

/// R16: Subscription tiers for Dust
public enum DustSubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case team = "team"
    
    public var displayName: String {
        switch self { case .free: return "Free"; case .pro: return "Dust Pro"; case .team: return "Dust Team" }
    }
    public var monthlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 3.99; case .team: return 7.99 }
    }
    public var maxSessions: Int? {
        switch self { case .free: return 20; case .pro: return nil; case .team: return nil }
    }
    public var supportsWidgets: Bool { self != .free }
    public var supportsShortcuts: Bool { self != .free }
    public var supportsTeam: Bool { self == .team }
    public var trialDays: Int { self == .free ? 0 : 14 }
}

public struct DustSubscription: Codable {
    public let tier: DustSubscriptionTier
    public let status: String
    public let expiresAt: Date?
    public init(tier: DustSubscriptionTier, status: String = "active", expiresAt: Date? = nil) {
        self.tier = tier; self.status = status; self.expiresAt = expiresAt
    }
}
