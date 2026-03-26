import Foundation

// MARK: - Dust R12-R15 Models

struct CleanupProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var tasks: [CleanupTask]
    var schedule: CleanupSchedule?
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        tasks: [CleanupTask] = [],
        schedule: CleanupSchedule? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.tasks = tasks
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

struct CleanupTask: Identifiable, Codable {
    let id: UUID
    var type: CleanupTaskType
    var isEnabled: Bool
    var targetPaths: [String]
    var minAge: TimeInterval?
    var minSize: Int64?

    init(
        id: UUID = UUID(),
        type: CleanupTaskType,
        isEnabled: Bool = true,
        targetPaths: [String] = [],
        minAge: TimeInterval? = nil,
        minSize: Int64? = nil
    ) {
        self.id = id
        self.type = type
        self.isEnabled = isEnabled
        self.targetPaths = targetPaths
        self.minAge = minAge
        self.minSize = minSize
    }
}

enum CleanupTaskType: String, Codable, CaseIterable {
    case tempFiles = "Temporary Files"
    case cacheFiles = "Cache Files"
    case logs = "Log Files"
    case downloads = "Old Downloads"
    case trash = "Trash"
    case duplicates = "Duplicates"
    case buildArtifacts = "Build Artifacts"
    case oldBackups = "Old Backups"

    var icon: String {
        switch self {
        case .tempFiles: return "doc.badge.gearshape"
        case .cacheFiles: return "cylinder"
        case .logs: return "doc.text"
        case .downloads: return "arrow.down.circle"
        case .trash: return "trash"
        case .duplicates: return "doc.on.doc"
        case .buildArtifacts: return "hammer"
        case .oldBackups: return "clock.arrow.circlepath"
        }
    }
}

struct CleanupSchedule: Codable {
    var type: ScheduleType
    var dayOfWeek: Int?
    var hour: Int
    var minute: Int

    enum ScheduleType: String, Codable {
        case daily
        case weekly
        case monthly
    }

    init(type: ScheduleType = .daily, dayOfWeek: Int? = nil, hour: Int = 3, minute: Int = 0) {
        self.type = type
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.minute = minute
    }
}

struct CleanupResult: Identifiable, Codable {
    let id: UUID
    var profileId: UUID
    var tasks: [TaskResult]
    var totalFreedSpace: Int64
    var duration: TimeInterval
    var completedAt: Date
    var errors: [CleanupError]

    init(
        id: UUID = UUID(),
        profileId: UUID,
        tasks: [TaskResult] = [],
        totalFreedSpace: Int64 = 0,
        duration: TimeInterval = 0,
        completedAt: Date = Date(),
        errors: [CleanupError] = []
    ) {
        self.id = id
        self.profileId = profileId
        self.tasks = tasks
        self.totalFreedSpace = totalFreedSpace
        self.duration = duration
        self.completedAt = completedAt
        self.errors = errors
    }
}

struct TaskResult: Identifiable, Codable {
    let id: UUID
    var taskType: CleanupTaskType
    var filesDeleted: Int
    var spaceFreed: Int64
    var errors: [String]

    init(
        id: UUID = UUID(),
        taskType: CleanupTaskType,
        filesDeleted: Int = 0,
        spaceFreed: Int64 = 0,
        errors: [String] = []
    ) {
        self.id = id
        self.taskType = taskType
        self.filesDeleted = filesDeleted
        self.spaceFreed = spaceFreed
        self.errors = errors
    }
}

struct CleanupError: Identifiable, Codable {
    let id: UUID
    var filePath: String
    var errorMessage: String

    init(id: UUID = UUID(), filePath: String, errorMessage: String) {
        self.id = id
        self.filePath = filePath
        self.errorMessage = errorMessage
    }
}

struct CleanupStatistics: Codable {
    var totalCleanups: Int
    var totalSpaceFreed: Int64
    var favoriteCategory: CleanupTaskType?
    var averageDuration: TimeInterval
    var lastCleanupDate: Date?
    var spaceByCategory: [CleanupTaskType: Int64]
}
