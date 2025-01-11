import Foundation

extension URLSession {
    typealias JSONData = [String: Any]
    
    enum ConnectionResult {
        case success(String), failure(Error)
    }
    
    enum customError: Error {
        case invalidUrl
        case invalidData
        case tokenExpired
    }
    
    func request<T: Codable>(url: URL?, httpMethod: String?, authTokenString:String, headers:[String:String], payload: JSONData? = nil, expecting type: T.Type, completion: @escaping(Result<T, Error>) -> Void) {
        guard let url = url else {
            completion(.failure(customError.invalidUrl))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = headers
        request.addValue("Bearer " + authTokenString, forHTTPHeaderField: "Authorization")
        
        print("API request: ----- \(request)")
        
        if payload?.isEmpty == false {
            guard let body = try? JSONSerialization.data(withJSONObject: payload ?? [:], options: .prettyPrinted) else {
                print("\n Serialization failed")
                return
            }
            request.httpBody = body
        }
        
        let task = dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(customError.invalidData))
                }
                return
            }

            // Check for HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                // Handle token expiration case (401 Unauthorized)
                if httpResponse.statusCode == 401 {
                    completion(.failure(customError.tokenExpired))
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

                completion(.failure(customError.invalidData))
            } catch {
                // For other errors that aren't DecodingError
                debugPrint("Decoding error: \(error.localizedDescription)")
                completion(.failure(customError.invalidData))
            }

        }
        task.resume()
    }
}
