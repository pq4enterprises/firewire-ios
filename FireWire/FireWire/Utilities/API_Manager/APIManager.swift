import Foundation
import UIKit

extension URLSession {
    typealias JSONData = [String: Any]

    func request<T: Codable>(url: URL?, httpMethod: String?, authTokenString: String, headers: [String: String], payload: Any? = nil, expecting type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = url else {
            completion(.failure(APIError.invalidUrl))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = headers
        request.addValue("Bearer " + authTokenString, forHTTPHeaderField: "Authorization")

        debugPrint("API request: ----- \(request)")

        if let payload = payload {
            do {
                let body = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
                request.httpBody = body

                if let jsonString = String(data: body, encoding: .utf8) {
                    debugPrint("POST Payload: \(jsonString)")
                }

            } catch {
                completion(.failure(APIError.invalidData))
                return
            }
        }

        let task = dataTask(with: request) { data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorNotConnectedToInternet {
                    completion(.failure(APIError.noInternet))
                } else {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidData))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.invalidData))
                return
            }

            switch httpResponse.statusCode {
                case 200 ... 299:
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decodedResponse))
                    } catch {
                        debugPrint("Decoding failed with error: \(error)")
                        completion(.failure(APIError.invalidData))
                    }
                case 401:
                    completion(.failure(APIError.tokenExpired))
                default:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                    completion(.failure(APIError.serverError(code: httpResponse.statusCode, message: errorMessage)))
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
