import Foundation

public enum ByteFormatter {
    public static func string(from bytes: Int64) -> String {
        if bytes < 1_024 {
            return "\(bytes) B"
        }

        let units = ["KB", "MB", "GB", "TB"]
        var value = Double(bytes) / 1_024
        var unitIndex = 0

        while value >= 1_024, unitIndex < units.count - 1 {
            value /= 1_024
            unitIndex += 1
        }

        if value.rounded() == value {
            return "\(Int(value)) \(units[unitIndex])"
        }

        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
