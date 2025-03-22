import Foundation
import UIKit

extension URLSession {
    typealias JSONData = [String: Any]
    
    enum ConnectionResult {
        case success(String), failure(Error)
    }
    
    enum CustomError: Error {
        case invalidUrl
        case invalidData
        case tokenExpired
        case noInternet
    }
    
    func request<T: Codable>(url: URL?, httpMethod: String?, authTokenString:String, headers:[String:String], payload: Any? = nil, expecting type: T.Type, completion: @escaping(Result<T, Error>) -> Void) {
        guard let url = url else {
            completion(.failure(CustomError.invalidUrl))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = headers
        request.addValue("Bearer " + authTokenString, forHTTPHeaderField: "Authorization")
        
        print("API request: ----- \(request)")
        
        if let payload = payload {
            guard let body = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
                print("\n Serialization failed")
                return
            }

            if let jsonString = String(data: body, encoding: .utf8) {
                print("POST Payload: \(jsonString)")
            }

            request.httpBody = body
        }
        
        let task = dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(CustomError.invalidData))
                }
                return
            }

            // Check for HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                // Handle token expiration case (401 Unauthorized)
                if httpResponse.statusCode == 401 {
                    completion(.failure(CustomError.tokenExpired))
                    return
                }
            }

            do {
                let result = try JSONDecoder().decode(type.self, from: data)
                completion(.success(result))
            } catch let decodingError as DecodingError {
                // Handle specific DecodingError cases
                switch decodingError {
                case .typeMismatch(let type, let context):
                    debugPrint("Type mismatch error: Expected type \(type), but found \(context.debugDescription)")
                    debugPrint("Coding Path: \(context.codingPath)")

                case .valueNotFound(let value, let context):
                    debugPrint("Value not found error: Expected value \(value) but found none.")
                    debugPrint("Coding Path: \(context.codingPath)")

                case .keyNotFound(let key, let context):
                    debugPrint("Key not found error: Missing key \(key) in the response.")
                    debugPrint("Coding Path: \(context.codingPath)")

                case .dataCorrupted(let context):
                    debugPrint("Data corrupted error: The data is malformed or invalid.")
                    debugPrint("Coding Path: \(context.codingPath)")

                @unknown default:
                    debugPrint("Unknown Decoding Error: \(decodingError.localizedDescription)")
                }

                completion(.failure(CustomError.invalidData))
            } catch {
                // For other errors that aren't DecodingError
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    debugPrint("No internet connection")
                    completion(.failure(CustomError.noInternet))  // Define a 'noInternet' error in your customError enum
                } else {
                    debugPrint("Decoding error: \(error.localizedDescription)")
                    completion(.failure(CustomError.invalidData))
                }
            }

        }
        task.resume()
    }

    // Helper function to check if payload is empty (whether it is a dictionary or array)
    func isEmptyPayload(_ payload: Any) -> Bool {
        if let dict = payload as? [String: Any] {
            return dict.isEmpty
        } else if let array = payload as? [Any] {
            return array.isEmpty
        }
        return false
    }
}
