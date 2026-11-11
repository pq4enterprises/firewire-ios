//
//  FWDateFormatter.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/12/24.
//

import Foundation

class FWDateFormatter {
    // Shared instance of DateFormatter to parse the input date string
    private let inputDateFormatter: DateFormatter
    // Shared instance of DateFormatter to format the date into the desired string format
    private let outputDateFormatter: DateFormatter

    init(inputDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
        // Initialize the input date formatter for ISO 8601 with milliseconds and UTC time zone
        inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = inputDateFormat
        inputDateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        // Initialize the output date formatter with the desired format
        outputDateFormatter = DateFormatter()
        // 24-hour clock everywhere (iteration 1). en_US_POSIX pins the pattern so
        // the device's 12/24-hour setting cannot rewrite "HH" back to "h a".
        outputDateFormatter.dateFormat = "dd MMM | HH:mm"
        outputDateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    // Method to convert an ISO 8601 string into the custom format
    func formatDateString(_ isoDateString: String) -> String? {
        // Convert the input ISO8601 date string to a Date object
        guard let date = inputDateFormatter.date(from: isoDateString) else {
            return nil
        }

        // Return the formatted date string
        return outputDateFormatter.string(from: date)
    }

    /// "HH:mm" (24-hour, device time zone) for timeline rows such as the
    /// incident progression card. Accepts timestamps with or without
    /// fractional seconds.
    func formatTimeString(_ isoDateString: String) -> String? {
        var date = inputDateFormatter.date(from: isoDateString)
        if date == nil {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: isoDateString)
        }
        guard let date else { return nil }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        return timeFormatter.string(from: date)
    }

    func formatDateWithPOSIX(_ isoDateString: String) -> String? {
        let posixFormatter = DateFormatter()
        posixFormatter.dateFormat = inputDateFormatter.dateFormat
        posixFormatter.locale = Locale(identifier: "en_US_POSIX")
        posixFormatter.timeZone = TimeZone(abbreviation: "UTC")

        guard let date = posixFormatter.date(from: isoDateString) else {
            return nil
        }

        outputDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return outputDateFormatter.string(from: date)
    }
}
