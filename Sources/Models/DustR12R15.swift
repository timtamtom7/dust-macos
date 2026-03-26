import Foundation

// MARK: - Dust R12: Collaboration & Team Focus

/// Service for team-based focus sessions, accountability partners, and team challenges
final class TeamFocusService: ObservableObject {
    static let shared = TeamFocusService()

    @Published var teamSessions: [TeamFocusSession] = []
    @Published var accountabilityPartners: [AccountabilityPartner] = []
    @Published var teamChallenges: [TeamChallenge] = []
    @Published var sharedAllowlists: [SharedAllowlist] = []

    private init() {
        loadState()
    }

    // MARK: - Team Focus Sessions

    func startTeamSession(duration: TimeInterval, participants: [String]) -> TeamFocusSession {
        let session = TeamFocusSession(
            id: UUID(),
            startTime: Date(),
            duration: duration,
            participants: participants,
            status: .active
        )
        teamSessions.append(session)
        saveState()
        return session
    }

    func endTeamSession(_ id: UUID) {
        guard let idx = teamSessions.firstIndex(where: { $0.id == id }) else { return }
        teamSessions[idx].status = .ended
        saveState()
    }

    // MARK: - Accountability Partners

    func addPartner(name: String, email: String) -> AccountabilityPartner {
        let partner = AccountabilityPartner(id: UUID(), name: name, email: email, focusStats: FocusStats())
        accountabilityPartners.append(partner)
        saveState()
        return partner
    }

    func sendNudge(to partnerId: UUID) {
        guard let idx = accountabilityPartners.firstIndex(where: { $0.id == partnerId }) else { return }
        accountabilityPartners[idx].nudgesReceived += 1
        saveState()
    }

    // MARK: - Team Challenges

    func createChallenge(name: String, target: Double, unit: ChallengeUnit) -> TeamChallenge {
        let challenge = TeamChallenge(id: UUID(), name: name, target: target, unit: unit, participants: [], progress: 0, status: .active)
        teamChallenges.append(challenge)
        saveState()
        return challenge
    }

    func joinChallenge(_ id: UUID, memberName: String) {
        guard let idx = teamChallenges.firstIndex(where: { $0.id == id }) else { return }
        teamChallenges[idx].participants.append(memberName)
        saveState()
    }

    // MARK: - Shared Allowlists

    func addSharedAllowlist(name: String, allowedSites: [String], blockedSites: [String]) -> SharedAllowlist {
        let list = SharedAllowlist(id: UUID(), name: name, allowedSites: allowedSites, blockedSites: blockedSites)
        sharedAllowlists.append(list)
        saveState()
        return list
    }

    // MARK: - Persistence

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Dust/team.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = TeamFocusState(teamSessions: teamSessions, accountabilityPartners: accountabilityPartners, teamChallenges: teamChallenges, sharedAllowlists: sharedAllowlists)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(TeamFocusState.self, from: data) else { return }
        teamSessions = state.teamSessions
        accountabilityPartners = state.accountabilityPartners
        teamChallenges = state.teamChallenges
        sharedAllowlists = state.sharedAllowlists
    }
}

// MARK: - Models

struct TeamFocusSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var duration: TimeInterval
    var participants: [String]
    var status: SessionStatus
}

enum SessionStatus: String, Codable { case active, ended }

struct AccountabilityPartner: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var focusStats: FocusStats
    var nudgesReceived: Int = 0
}

struct FocusStats: Codable {
    var totalFocusTimeToday: TimeInterval = 0
    var streak: Int = 0
}

struct TeamChallenge: Identifiable, Codable {
    let id: UUID
    var name: String
    var target: Double
    var unit: ChallengeUnit
    var participants: [String]
    var progress: Double
    var status: ChallengeStatus
}

enum ChallengeUnit: String, Codable { case hours, days, sessions }
enum ChallengeStatus: String, Codable { case active, completed, failed }

struct SharedAllowlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var allowedSites: [String]
    var blockedSites: [String]
}

struct TeamFocusState: Codable {
    var teamSessions: [TeamFocusSession]
    var accountabilityPartners: [AccountabilityPartner]
    var teamChallenges: [TeamChallenge]
    var sharedAllowlists: [SharedAllowlist]
}
