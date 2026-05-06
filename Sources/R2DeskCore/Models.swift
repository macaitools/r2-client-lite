import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public var profiles: [StorageProfile]
    public var favoriteBucketIDs: [UUID]
    public var recentBucketIDs: [UUID]
    public var history: [OperationHistoryEntry]
    public var favoriteDirectories: [FavoriteDirectory]
    public var languageCode: String

    public init(
        profiles: [StorageProfile] = [],
        favoriteBucketIDs: [UUID] = [],
        recentBucketIDs: [UUID] = [],
        history: [OperationHistoryEntry] = [],
        favoriteDirectories: [FavoriteDirectory] = [],
        languageCode: String = "zh"
    ) {
        self.profiles = profiles
        self.favoriteBucketIDs = favoriteBucketIDs
        self.recentBucketIDs = recentBucketIDs
        self.history = history
        self.favoriteDirectories = favoriteDirectories
        self.languageCode = languageCode
    }

    private enum CodingKeys: String, CodingKey {
        case profiles
        case favoriteBucketIDs
        case recentBucketIDs
        case history
        case favoriteDirectories
        case languageCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profiles = try container.decodeIfPresent([StorageProfile].self, forKey: .profiles) ?? []
        favoriteBucketIDs = try container.decodeIfPresent([UUID].self, forKey: .favoriteBucketIDs) ?? []
        recentBucketIDs = try container.decodeIfPresent([UUID].self, forKey: .recentBucketIDs) ?? []
        history = try container.decodeIfPresent([OperationHistoryEntry].self, forKey: .history) ?? []
        favoriteDirectories = try container.decodeIfPresent([FavoriteDirectory].self, forKey: .favoriteDirectories) ?? []
        languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode) ?? "zh"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profiles, forKey: .profiles)
        try container.encode(favoriteBucketIDs, forKey: .favoriteBucketIDs)
        try container.encode(recentBucketIDs, forKey: .recentBucketIDs)
        try container.encode(history, forKey: .history)
        try container.encode(favoriteDirectories, forKey: .favoriteDirectories)
        try container.encode(languageCode, forKey: .languageCode)
    }
}

public struct FavoriteDirectory: Codable, Equatable, Hashable, Sendable {
    public var bucketID: UUID
    public var bucketName: String
    public var prefix: String

    public init(bucketID: UUID, bucketName: String, prefix: String) {
        self.bucketID = bucketID
        self.bucketName = bucketName
        self.prefix = prefix
    }
}

public struct StorageProfile: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var buckets: [BucketConfig]

    public init(id: UUID = UUID(), name: String, buckets: [BucketConfig] = []) {
        self.id = id
        self.name = name
        self.buckets = buckets
    }
}

public struct BucketConfig: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var displayName: String
    public var bucketName: String
    public var endpoint: URL
    public var region: String
    public var accessKeyID: String
    public var publicBaseURL: URL?

    public init(
        id: UUID = UUID(),
        displayName: String,
        bucketName: String,
        endpoint: URL,
        region: String,
        accessKeyID: String,
        publicBaseURL: URL? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.bucketName = bucketName
        self.endpoint = endpoint
        self.region = region
        self.accessKeyID = accessKeyID
        self.publicBaseURL = publicBaseURL
    }
}

public struct S3Credentials: Equatable, Sendable {
    public var accessKeyID: String
    public var secretAccessKey: String

    public init(accessKeyID: String, secretAccessKey: String) {
        self.accessKeyID = accessKeyID
        self.secretAccessKey = secretAccessKey
    }
}

public struct ObjectItem: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { key }
    public var key: String
    public var size: Int64
    public var lastModified: Date?
    public var storageClass: String?
    public var eTag: String?

    public init(key: String, size: Int64, lastModified: Date? = nil, storageClass: String? = nil, eTag: String? = nil) {
        self.key = key
        self.size = size
        self.lastModified = lastModified
        self.storageClass = storageClass
        self.eTag = eTag
    }
}

public struct ObjectPrefix: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { prefix }
    public var prefix: String

    public var displayName: String {
        let trimmed = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.split(separator: "/").last.map(String.init) ?? prefix
    }

    public init(prefix: String) {
        self.prefix = prefix
    }
}

public struct S3Listing: Equatable, Sendable {
    public var objects: [ObjectItem]
    public var prefixes: [ObjectPrefix]

    public init(objects: [ObjectItem] = [], prefixes: [ObjectPrefix] = []) {
        self.objects = objects
        self.prefixes = prefixes
    }
}

public struct ObjectDetails: Equatable, Sendable {
    public var item: ObjectItem
    public var contentType: String?
    public var eTag: String?
    public var metadata: [String: String]

    public init(item: ObjectItem, contentType: String? = nil, eTag: String? = nil, metadata: [String: String] = [:]) {
        self.item = item
        self.contentType = contentType
        self.eTag = eTag
        self.metadata = metadata
    }
}

public struct OperationHistoryEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var bucketName: String
    public var action: String
    public var detail: String
    public var succeeded: Bool

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        bucketName: String,
        action: String,
        detail: String,
        succeeded: Bool
    ) {
        self.id = id
        self.date = date
        self.bucketName = bucketName
        self.action = action
        self.detail = detail
        self.succeeded = succeeded
    }
}

public struct BucketUsage: Equatable, Sendable {
    public var objectCount: Int
    public var totalBytes: Int64

    public init(objects: [ObjectItem]) {
        objectCount = objects.count
        totalBytes = objects.reduce(0) { $0 + $1.size }
    }
}

public extension JSONEncoder {
    static var r2Desk: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public extension JSONDecoder {
    static var r2Desk: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
