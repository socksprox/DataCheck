import Foundation

struct DateHelper {
    static func format(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Parse as UTC

        guard let date = formatter.date(from: dateString) else {
            return dateString // Return original string if parsing fails
        }

        let outputFormatter = DateFormatter()
        outputFormatter.timeZone = .current // Use the system's current timezone for display

        if Calendar.current.isDateInToday(date) {
            outputFormatter.dateFormat = "'Today at' HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            outputFormatter.dateFormat = "'Yesterday at' HH:mm"
        } else {
            outputFormatter.dateFormat = "MMMM d 'at' HH:mm"
        }

        return outputFormatter.string(from: date)
    }
}
