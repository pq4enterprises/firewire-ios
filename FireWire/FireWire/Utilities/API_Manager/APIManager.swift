import Foundation

extension URLSession {
    typealias JSONData = [String: Any]
    
    enum ConnectionResult {
        case success(String), failure(Error)
    }
    
    enum customError: Error {
        case invaliedUrl
        case invaliedData
    }
    
    func request<T: Codable>(url: URL?, httpMethod: String?, authTokenString:String, headers:[String:String], payload: JSONData? = nil, expecting type: T.Type, completion: @escaping(Result<T, Error>) -> Void) {
        guard let url = url else {
            completion(.failure(customError.invaliedUrl))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = headers
        request.addValue("Bearer " + authTokenString, forHTTPHeaderField: "Authorization")
        print("request: ----- \(request)")
        if payload?.isEmpty == false {
            guard let body = try? JSONSerialization.data(withJSONObject: payload ?? [:], options: .prettyPrinted) else {
                print("\n serilization falied")
                return
            }
            request.httpBody = body
        }
        
        let task = dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(customError.invaliedData))
                }
                return
            }
            do {
                let result = try JSONDecoder().decode(type.self, from: data)                
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
