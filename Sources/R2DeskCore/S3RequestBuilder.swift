import Foundation

public enum S3RequestBuilder {
    public static func objectURL(for bucket: BucketConfig, key: String) throws -> URL {
        let path = [bucket.bucketName] + key.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        return try endpointURL(bucket.endpoint, pathComponents: path)
    }

    public static func listURL(for bucket: BucketConfig, prefix: String? = nil, delimiter: String? = nil) throws -> URL {
        var components = URLComponents(url: try endpointURL(bucket.endpoint, pathComponents: [bucket.bucketName]), resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "list-type", value: "2"),
            URLQueryItem(name: "prefix", value: prefix ?? "")
        ]
        if let delimiter {
            queryItems.append(URLQueryItem(name: "delimiter", value: delimiter))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw S3Error.invalidURL
        }
        return url
    }

    public static func presignedDownloadURL(
        for bucket: BucketConfig,
        key: String,
        credentials: S3Credentials,
        expiresIn: Int,
        date: Date = Date()
    ) throws -> URL {
        try S3Signer.presignedURL(
            method: "GET",
            url: objectURL(for: bucket, key: key),
            region: bucket.region,
            credentials: credentials,
            expiresIn: expiresIn,
            date: date
        )
    }

    public static func request(
        method: String,
        url: URL,
        bucket: BucketConfig,
        credentials: S3Credentials,
        body: Data = Data(),
        contentType: String? = nil,
        headers: [String: String] = [:]
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body.isEmpty ? nil : body
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        try S3Signer.sign(&request, region: bucket.region, credentials: credentials, body: body)
        return request
    }

    public static func copySource(bucketName: String, key: String) -> String {
        let encodedKey = key
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { S3Signer.awsEncode(String($0)) }
            .joined(separator: "/")
        return "/\(bucketName)/\(encodedKey)"
    }

    private static func endpointURL(_ endpoint: URL, pathComponents: [String]) throws -> URL {
        var url = endpoint
        for component in pathComponents {
            url.appendPathComponent(component)
        }
        guard url.scheme != nil, url.host != nil else {
            throw S3Error.invalidURL
        }
        return url
    }
}
