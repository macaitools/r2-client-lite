import Foundation
import UniformTypeIdentifiers

public enum MIMETypeDetector {
    public static func contentType(for fileURL: URL) -> String {
        let ext = fileURL.pathExtension.lowercased()
        guard !ext.isEmpty else {
            return "application/octet-stream"
        }

        if let type = UTType(filenameExtension: ext), let mimeType = type.preferredMIMEType {
            return mimeType
        }

        return fallback[ext] ?? "application/octet-stream"
    }

    private static let fallback = [
        "js": "text/javascript",
        "json": "application/json",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "md": "text/markdown",
        "csv": "text/csv"
    ]
}
