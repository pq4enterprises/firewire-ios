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

       init() {
           // Initialize the input date formatter for ISO 8601 with milliseconds and UTC time zone
           inputDateFormatter = DateFormatter()
           inputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"  // Match the exact input format
           inputDateFormatter.timeZone = TimeZone(abbreviation: "UTC")  // Ensure it's in UTC time zone

           // Initialize the output date formatter with the desired format
           outputDateFormatter = DateFormatter()
           outputDateFormatter.dateFormat = "dd MMM | hh:mm a"
           outputDateFormatter.locale = Locale(identifier: "en_US")  // Optional: Locale for AM/PM format
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
}
