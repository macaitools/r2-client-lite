import Foundation

public enum UniqueKeyResolver {
    public static func availableKey(for desiredKey: String, existingKeys: Set<String>) -> String {
        guard existingKeys.contains(desiredKey) else {
            return desiredKey
        }

        let nsKey = desiredKey as NSString
        let directory = nsKey.deletingLastPathComponent
        let fileName = nsKey.lastPathComponent as NSString
        let ext = fileName.pathExtension
        let base = ext.isEmpty ? fileName as String : fileName.deletingPathExtension
        var index = 2

        while true {
            let candidateName = ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
            let candidate = directory == "." || directory.isEmpty
                ? candidateName
                : "\(directory)/\(candidateName)"
            if !existingKeys.contains(candidate) {
                return candidate
            }
            index += 1
        }
    }
}
