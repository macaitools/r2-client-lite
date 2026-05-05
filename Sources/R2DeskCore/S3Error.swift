import Foundation

public enum S3Error: Error, LocalizedError {
    case invalidURL
    case missingSecret
    case unexpectedResponse
    case requestFailed(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid endpoint URL."
        case .missingSecret:
            return "Missing access secret."
        case .unexpectedResponse:
            return "Unexpected storage response."
        case let .requestFailed(statusCode, body):
            return "Storage request failed (\(statusCode)). \(body)"
        }
    }
}
