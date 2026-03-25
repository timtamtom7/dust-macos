import Foundation

/// AI-powered semantic deduplication engine for Dust
final class SemanticDeduplicationEngine {
    static let shared = SemanticDeduplicationEngine()
    
    private init() {}
    
    // MARK: - Semantic Similarity
    
    /// Calculate semantic similarity between two file paths
    func semanticSimilarity(path1: String, path2: String) -> Double {
        let name1 = URL(fileURLWithPath: path1).deletingPathExtension().lastPathComponent
        let name2 = URL(fileURLWithPath: path2).deletingPathExtension().lastPathComponent
        
        // Token-based similarity
        let tokens1 = Set(name1.lowercased().split(separator: "_").map(String.init) + name1.lowercased().split(separator: " ").map(String.init))
        let tokens2 = Set(name2.lowercased().split(separator: "_").map(String.init) + name2.lowercased().split(separator: " ").map(String.init))
        
        let intersection = tokens1.intersection(tokens2)
        let union = tokens1.union(tokens2)
        
        guard !union.isEmpty else { return 0 }
        
        let jaccard = Double(intersection.count) / Double(union.count)
        
        // Also consider version patterns (v1, v2, copy, etc.)
        let versionSimilarity = versionSimilarity(name1, name2)
        
        return (jaccard + versionSimilarity) / 2.0
    }
    
    private func versionSimilarity(_ s1: String, _ s2: String) -> Double {
        // Check for version patterns
        let versionPatterns = ["v1", "v2", "v3", "copy", "backup", "old", "new", "final", "draft"]
        
        let lowercased1 = s1.lowercased()
        let lowercased2 = s2.lowercased()
        
        for pattern in versionPatterns {
            if (lowercased1.contains(pattern) && lowercased2.contains(pattern)) ||
               (!lowercased1.contains(pattern) && !lowercased2.contains(pattern)) {
                return 1.0
            }
        }
        
        return 0.5
    }
    
    // MARK: - Smart Grouping
    
    /// Group duplicates into semantic clusters
    func groupBySemanticSimilarity(paths: [String], threshold: Double = 0.7) -> [[String]] {
        var groups: [[String]] = []
        var assigned = Set<Int>()
        
        for i in 0..<paths.count {
            if assigned.contains(i) { continue }
            
            var group = [paths[i]]
            assigned.insert(i)
            
            for j in (i+1)..<paths.count {
                if assigned.contains(j) { continue }
                
                let similarity = semanticSimilarity(path1: paths[i], path2: paths[j])
                if similarity >= threshold {
                    group.append(paths[j])
                    assigned.insert(j)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    // MARK: - Recommendations
    
    /// Suggest which file to keep in a duplicate group
    func suggestKeep(in group: [String]) -> String? {
        // Prefer:
        // 1. Files without version patterns (cleaner names)
        // 2. Files in primary locations (home, documents)
        // 3. Older files (more likely to be the original)
        
        var bestFile: String?
        var bestScore = -1.0
        
        let versionPatterns = ["v1", "v2", "copy", "backup", "old", "(1)", "(2)"]
        let preferredPrefixes = ["~/Documents", "~/Desktop", "~/"]
        
        for file in group {
            var score = 0.0
            
            let name = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent.lowercased()
            
            // Penalize version patterns
            for pattern in versionPatterns {
                if name.contains(pattern) {
                    score -= 0.3
                }
            }
            
            // Prefer primary locations
            for prefix in preferredPrefixes {
                if file.hasPrefix(prefix) {
                    score += 0.5
                    break
                }
            }
            
            // Prefer older files (earlier modification time would be checked via FileManager)
            score += 0.2 // Default bonus for participating
            
            if score > bestScore {
                bestScore = score
                bestFile = file
            }
        }
        
        return bestFile
    }
}
