import Foundation

public enum PrefixNavigator {
    public static func parent(of prefix: String) -> String {
        let trimmed = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var parts = trimmed.split(separator: "/").map(String.init)
        guard !parts.isEmpty else { return "" }
        parts.removeLast()
        return parts.isEmpty ? "" : parts.joined(separator: "/") + "/"
    }

    public static func folderKey(named name: String, in prefix: String) -> String {
        let cleanName = name.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPrefix = prefix.isEmpty || prefix.hasSuffix("/") ? prefix : prefix + "/"
        return "\(cleanPrefix)\(cleanName)/"
    }

    public static func childObjectKey(fileName: String, in prefix: String) -> String {
        let cleanPrefix = prefix.isEmpty || prefix.hasSuffix("/") ? prefix : prefix + "/"
        return "\(cleanPrefix)\(fileName)"
    }
}
