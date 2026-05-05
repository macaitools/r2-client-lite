import Foundation

public final class ConfigStore {
    public let configURL: URL

    public init(configURL: URL? = nil) {
        if let configURL {
            self.configURL = configURL
            return
        }

        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        self.configURL = baseURL
            .appendingPathComponent("R2Desk", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    public func load() throws -> AppConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return AppConfig()
        }

        let data = try Data(contentsOf: configURL)
        return try JSONDecoder.r2Desk.decode(AppConfig.self, from: data)
    }

    public func save(_ config: AppConfig) throws {
        let folder = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try JSONEncoder.r2Desk.encode(config)
        try data.write(to: configURL, options: [.atomic])
    }
}
