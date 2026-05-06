import CryptoKit
import Foundation

public enum S3Signer {
    public static func canonicalQuery(_ items: [URLQueryItem]) -> String {
        let encodedItems: [(String, String)] = items.map { item in
            (awsEncode(item.name), awsEncode(item.value ?? ""))
        }
        return encodedItems
            .sorted { lhs, rhs in
                lhs.0 == rhs.0 ? lhs.1 < rhs.1 : lhs.0 < rhs.0
            }
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "&")
    }

    public static func sign(
        _ request: inout URLRequest,
        region: String,
        credentials: S3Credentials,
        body: Data = Data(),
        date: Date = Date()
    ) throws {
        guard let url = request.url, let host = url.host else {
            throw S3Error.invalidURL
        }

        let timestamp = awsTimestamp.string(from: date)
        let dateStamp = awsDate.string(from: date)
        let payloadHash = sha256Hex(body)

        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(timestamp, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")

        var signedHeaders: [String: String] = [:]
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            signedHeaders[key.lowercased()] = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let headerLines = signedHeaders
            .keys
            .sorted()
            .map { "\($0):\(signedHeaders[$0]!)\n" }
            .joined()
        let signedHeaderNames = signedHeaders.keys.sorted().joined(separator: ";")
        let canonicalRequest = [
            request.httpMethod ?? "GET",
            canonicalPath(URLComponents(url: url, resolvingAgainstBaseURL: false)?.path ?? url.path),
            canonicalQuery(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []),
            headerLines,
            signedHeaderNames,
            payloadHash
        ].joined(separator: "\n")

        let scope = "\(dateStamp)/\(region)/s3/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            timestamp,
            scope,
            sha256Hex(Data(canonicalRequest.utf8))
        ].joined(separator: "\n")

        let signature = hmac(
            key: signingKey(secret: credentials.secretAccessKey, date: dateStamp, region: region),
            message: stringToSign
        )
            .map { String(format: "%02x", $0) }
            .joined()

        let authorization = "AWS4-HMAC-SHA256 Credential=\(credentials.accessKeyID)/\(scope), SignedHeaders=\(signedHeaderNames), Signature=\(signature)"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
    }

    public static func presignedURL(
        method: String,
        url: URL,
        region: String,
        credentials: S3Credentials,
        expiresIn: Int,
        date: Date = Date()
    ) throws -> URL {
        guard let host = url.host else {
            throw S3Error.invalidURL
        }

        let timestamp = awsTimestamp.string(from: date)
        let dateStamp = awsDate.string(from: date)
        let scope = "\(dateStamp)/\(region)/s3/aws4_request"
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(contentsOf: [
            URLQueryItem(name: "X-Amz-Algorithm", value: "AWS4-HMAC-SHA256"),
            URLQueryItem(name: "X-Amz-Credential", value: "\(credentials.accessKeyID)/\(scope)"),
            URLQueryItem(name: "X-Amz-Date", value: timestamp),
            URLQueryItem(name: "X-Amz-Expires", value: "\(expiresIn)"),
            URLQueryItem(name: "X-Amz-SignedHeaders", value: "host")
        ])

        let canonicalRequest = [
            method,
            canonicalPath(URLComponents(url: url, resolvingAgainstBaseURL: false)?.path ?? url.path),
            canonicalQuery(queryItems),
            "host:\(host)\n",
            "host",
            "UNSIGNED-PAYLOAD"
        ].joined(separator: "\n")

        let stringToSign = [
            "AWS4-HMAC-SHA256",
            timestamp,
            scope,
            sha256Hex(Data(canonicalRequest.utf8))
        ].joined(separator: "\n")
        let signature = hmac(
            key: signingKey(secret: credentials.secretAccessKey, date: dateStamp, region: region),
            message: stringToSign
        )
            .map { String(format: "%02x", $0) }
            .joined()

        queryItems.append(URLQueryItem(name: "X-Amz-Signature", value: signature))
        components?.queryItems = queryItems
        guard let signedURL = components?.url else {
            throw S3Error.invalidURL
        }
        return signedURL
    }

    public static func awsEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    static func canonicalPath(_ path: String) -> String {
        path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { awsEncode(String($0)) }
            .joined(separator: "/")
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func signingKey(secret: String, date: String, region: String) -> SymmetricKey {
        let dateKey = hmac(key: Data("AWS4\(secret)".utf8), message: date)
        let regionKey = hmac(key: dateKey, message: region)
        let serviceKey = hmac(key: regionKey, message: "s3")
        return SymmetricKey(data: hmac(key: serviceKey, message: "aws4_request"))
    }

    private static func hmac(key: Data, message: String) -> Data {
        hmac(key: SymmetricKey(data: key), message: message)
    }

    private static func hmac(key: SymmetricKey, message: String) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key))
    }

    private static let awsTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }()

    private static let awsDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
