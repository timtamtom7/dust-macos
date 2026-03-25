import Foundation

struct ExclusionPattern: Identifiable, Codable {
    let id: UUID
    var pattern: String
    var isRegex: Bool
    var isEnabled: Bool
}

final class ExclusionManager {
    static let shared = ExclusionManager()

    private let patternsKey = "exclusionPatterns"

    private init() {}

    func fetchPatterns() -> [ExclusionPattern] {
        guard let data = UserDefaults.standard.data(forKey: patternsKey) else { return defaultPatterns() }
        do {
            return try JSONDecoder().decode([ExclusionPattern].self, from: data)
        } catch {
            return defaultPatterns()
        }
    }

    func savePattern(_ pattern: ExclusionPattern) {
        var patterns = fetchPatterns()
        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }
        savePatterns(patterns)
    }

    func deletePattern(_ id: UUID) {
        var patterns = fetchPatterns()
        patterns.removeAll { $0.id == id }
        savePatterns(patterns)
    }

    func shouldExclude(path: String) -> Bool {
        let patterns = fetchPatterns().filter { $0.isEnabled }
        for pattern in patterns {
            if pattern.isRegex {
                if let regex = try? NSRegularExpression(pattern: pattern.pattern) {
                    let range = NSRange(path.startIndex..., in: path)
                    if regex.firstMatch(in: path, range: range) != nil {
                        return true
                    }
                }
            } else {
                if path.contains(pattern.pattern) {
                    return true
                }
            }
        }
        return false
    }

    private func savePatterns(_ patterns: [ExclusionPattern]) {
        do {
            let data = try JSONEncoder().encode(patterns)
            UserDefaults.standard.set(data, forKey: patternsKey)
        } catch {
            print("Failed to save exclusion patterns: \(error)")
        }
    }

    private func defaultPatterns() -> [ExclusionPattern] {
        [
            ExclusionPattern(id: UUID(), pattern: "node_modules", isRegex: false, isEnabled: true),
            ExclusionPattern(id: UUID(), pattern: ".git", isRegex: false, isEnabled: true),
            ExclusionPattern(id: UUID(), pattern: "Caches", isRegex: false, isEnabled: false),
        ]
    }
}
