import Foundation

struct DuplicateFinderGroup: Identifiable {
    let id = UUID()
    let files: [URL]
    let size: UInt64
}

final class DuplicateFinder {
    static let shared = DuplicateFinder()

    private init() {}

    func findDuplicates(at url: URL, completion: @escaping ([DuplicateFinderGroup]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var sizeGroups: [UInt64: [URL]] = [:]

            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            while let fileURL = enumerator.nextObject() as? URL {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let size = attributes[.size] as? UInt64, size > 0 {
                        sizeGroups[size, default: []].append(fileURL)
                    }
                } catch {
                    continue
                }
            }

            var duplicates: [DuplicateFinderGroup] = []
            for (size, urls) in sizeGroups where urls.count > 1 && size > 1000 {
                duplicates.append(DuplicateFinderGroup(files: urls, size: size))
            }

            DispatchQueue.main.async {
                completion(duplicates)
            }
        }
    }

    func deleteDuplicates(keeping urls: [URL]) {
        let toDelete = urls.dropFirst()
        let fileManager = FileManager.default

        for url in toDelete {
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                print("Failed to delete \(url): \(error)")
            }
        }
    }
}
