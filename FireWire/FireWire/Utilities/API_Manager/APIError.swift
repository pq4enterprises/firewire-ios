//
//  APIError.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 29/03/25.
//

public enum APIError: Error {
    case invalidUrl
    case invalidData
    case tokenExpired
    case noInternet
    case serverError(code: Int, message: String)

    var localizedDescription: String {
        switch self {
        case .invalidUrl:
            return "Invalid URL."
        case .invalidData:
            return "Received invalid data from the server."
        case .tokenExpired:
            return "Session expired. Please log in again."
        case .noInternet:
            return "No internet connection. Please check your network."
        case .serverError(let code, let message):
            return "Server Error \(code): \(message)"
        }
    }
}
