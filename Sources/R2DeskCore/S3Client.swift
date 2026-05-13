import Foundation

public final class S3Client: @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func listObjects(in bucket: BucketConfig, credentials: S3Credentials, prefix: String = "") async throws -> [ObjectItem] {
        let url = try S3RequestBuilder.listURL(for: bucket, prefix: prefix)
        let request = try S3RequestBuilder.request(method: "GET", url: url, bucket: bucket, credentials: credentials)
        let data = try await send(request)
        return try S3ListParser.parse(data).objects
    }

    public func list(in bucket: BucketConfig, credentials: S3Credentials, prefix: String = "", delimiter: String = "/") async throws -> S3Listing {
        let url = try S3RequestBuilder.listURL(for: bucket, prefix: prefix, delimiter: delimiter)
        let request = try S3RequestBuilder.request(method: "GET", url: url, bucket: bucket, credentials: credentials)
        let data = try await send(request)
        return try S3ListParser.parse(data)
    }

    public func upload(fileURL: URL, to bucket: BucketConfig, credentials: S3Credentials, key: String? = nil) async throws {
        let objectKey = key ?? fileURL.lastPathComponent
        let data = try Data(contentsOf: fileURL)
        let url = try S3RequestBuilder.objectURL(for: bucket, key: objectKey)
        let request = try S3RequestBuilder.request(
            method: "PUT",
            url: url,
            bucket: bucket,
            credentials: credentials,
            body: data,
            contentType: MIMETypeDetector.contentType(for: fileURL)
        )
        _ = try await send(request)
    }

    public func createFolder(named name: String, in prefix: String, bucket: BucketConfig, credentials: S3Credentials) async throws {
        let key = PrefixNavigator.folderKey(named: name, in: prefix)
        let url = try S3RequestBuilder.objectURL(for: bucket, key: key)
        let request = try S3RequestBuilder.request(
            method: "PUT",
            url: url,
            bucket: bucket,
            credentials: credentials,
            contentType: "application/x-directory"
        )
        _ = try await send(request)
    }

    public func copyObject(from sourceKey: String, to destinationKey: String, in bucket: BucketConfig, credentials: S3Credentials) async throws {
        let url = try S3RequestBuilder.objectURL(for: bucket, key: destinationKey)
        let request = try S3RequestBuilder.request(
            method: "PUT",
            url: url,
            bucket: bucket,
            credentials: credentials,
            headers: ["x-amz-copy-source": S3RequestBuilder.copySource(bucketName: bucket.bucketName, key: sourceKey)]
        )
        _ = try await send(request)
    }

    public func moveObject(from sourceKey: String, to destinationKey: String, in bucket: BucketConfig, credentials: S3Credentials) async throws {
        try await copyObject(from: sourceKey, to: destinationKey, in: bucket, credentials: credentials)
        try await deleteObject(key: sourceKey, from: bucket, credentials: credentials)
    }

    public func deleteObject(key: String, from bucket: BucketConfig, credentials: S3Credentials) async throws {
        let url = try S3RequestBuilder.objectURL(for: bucket, key: key)
        let request = try S3RequestBuilder.request(method: "DELETE", url: url, bucket: bucket, credentials: credentials)
        _ = try await send(request)
    }

    public func downloadObject(key: String, from bucket: BucketConfig, credentials: S3Credentials, to folder: URL) async throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = try S3RequestBuilder.objectURL(for: bucket, key: key)
        let request = try S3RequestBuilder.request(method: "GET", url: url, bucket: bucket, credentials: credentials)
        let data = try await send(request)
        let localURL = folder.appendingPathComponent((key as NSString).lastPathComponent)
        try data.write(to: localURL, options: [.atomic])
        return localURL
    }

    public func details(for object: ObjectItem, in bucket: BucketConfig, credentials: S3Credentials) async throws -> ObjectDetails {
        let url = try S3RequestBuilder.objectURL(for: bucket, key: object.key)
        let request = try S3RequestBuilder.request(method: "HEAD", url: url, bucket: bucket, credentials: credentials)
        let response = try await sendReturningResponse(request)
        var metadata: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            let header = String(describing: key)
            if header.lowercased().hasPrefix("x-amz-meta-") {
                metadata[String(header.dropFirst("x-amz-meta-".count))] = String(describing: value)
            }
        }
        let eTag = response.value(forHTTPHeaderField: "ETag") ?? object.eTag
        return ObjectDetails(
            item: object,
            contentType: response.value(forHTTPHeaderField: "Content-Type"),
            eTag: eTag,
            metadata: metadata
        )
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw S3Error.unexpectedResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw S3Error.requestFailed(statusCode: http.statusCode, body: body)
        }
        return data
    }

    private func sendReturningResponse(_ request: URLRequest) async throws -> HTTPURLResponse {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw S3Error.unexpectedResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw S3Error.requestFailed(statusCode: http.statusCode, body: body)
        }
        return http
    }
}

enum S3ListParser {
    static func parse(_ data: Data) throws -> S3Listing {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw parser.parserError ?? S3Error.unexpectedResponse
        }
        return S3Listing(objects: delegate.objects, prefixes: delegate.prefixes)
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var objects: [ObjectItem] = []
        var prefixes: [ObjectPrefix] = []
        private var currentElement = ""
        private var currentText = ""
        private var key: String?
        private var prefix: String?
        private var size: Int64 = 0
        private var lastModified: Date?
        private var storageClass: String?
        private var eTag: String?
        private var insideContents = false
        private var insideCommonPrefix = false

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            currentElement = elementName
            currentText = ""
            if elementName == "Contents" {
                insideContents = true
                key = nil
                size = 0
                lastModified = nil
                storageClass = nil
                eTag = nil
            }
            if elementName == "CommonPrefixes" {
                insideCommonPrefix = true
                prefix = nil
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentText += string
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

            if insideCommonPrefix {
                if elementName == "Prefix" {
                    prefix = value
                } else if elementName == "CommonPrefixes" {
                    if let prefix {
                        prefixes.append(ObjectPrefix(prefix: prefix))
                    }
                    insideCommonPrefix = false
                }
                currentText = ""
                return
            }

            guard insideContents else { return }

            switch elementName {
            case "Key":
                key = value
            case "Size":
                size = Int64(value) ?? 0
            case "LastModified":
                lastModified = parseDate(value)
            case "StorageClass":
                storageClass = value
            case "ETag":
                eTag = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            case "Contents":
                if let key {
                    objects.append(ObjectItem(key: key, size: size, lastModified: lastModified, storageClass: storageClass, eTag: eTag))
                }
                insideContents = false
            default:
                break
            }
            currentText = ""
        }
    }
}

private func parseDate(_ value: String) -> Date? {
    let withFractionalSeconds = ISO8601DateFormatter()
    withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFractionalSeconds.date(from: value) {
        return date
    }

    let withoutFractionalSeconds = ISO8601DateFormatter()
    withoutFractionalSeconds.formatOptions = [.withInternetDateTime]
    return withoutFractionalSeconds.date(from: value)
}
