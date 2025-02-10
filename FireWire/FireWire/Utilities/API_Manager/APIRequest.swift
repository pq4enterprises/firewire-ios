//
//  APIRequest.swift
//  JP_apiSample
//
//

import UIKit
import XMLCoder

typealias JSON = [String: Any]

public class APIRequest {
    typealias DataCompletionBlock = (_ response: Any?, _ statusCode: Int?, _ error: String?) -> Void

    func callApi<T: Codable>(
        apiEndPoint: String?,
        payload: Any? = nil,
        expect: T.Type,
        requestType: String = APIConstants.POST, // Default to POST if not specified
        completionHandler: @escaping DataCompletionBlock
    ) {
        var urlString = APIEndpoints.baseURL + (apiEndPoint ?? "")
        let accessToken = UserDefaults.standard.string(forKey: "token")

        // For GET request, append parameters to the URL if provided
        if requestType == APIConstants.GET, let payload = payload as? [String: Any], isEmptyPayload(payload) == false {
            var urlComponents = URLComponents(string: urlString)
            urlComponents?.queryItems = payload.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = urlComponents?.url?.absoluteString ?? urlString
        }

        // Perform the API request
        URLSession.shared.request(url: URL(string: urlString),
                                  httpMethod: requestType,
                                  authTokenString: accessToken ?? "",
                                  headers: APIConstants.headers,
                                  payload: requestType == APIConstants.GET ? nil : payload,
                                  expecting: expect.self)
        { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
            }
        }
    }

    func fetchRSS<T: Codable>(apiEndPoint: String, modelType: T.Type, completionHandler: @escaping DataCompletionBlock) {
        guard let url = URL(string: apiEndPoint) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, "No data found")
                }
                return
            }

            // Decode the fetched XML data into the model
            do {
                // Use XMLDecoder to parse the XML data
                let decoder = XMLDecoder()
                let model = try decoder.decode(modelType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(model, nil, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
            }
        }

        task.resume()
    }

    func uploadImage<T: Codable>(
        apiEndPoint: String?,
        image: UIImage,
        expect: T.Type,
        requestType: String = APIConstants.POST,
        completionHandler: @escaping DataCompletionBlock
    ) {
        let urlString = APIEndpoints.baseURL + (apiEndPoint ?? "")

        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = requestType

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body = Data()

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let timestamp = Int(Date().timeIntervalSince1970)
            let uniqueFileName =  "image-\(timestamp).jpg"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(uniqueFileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Perform the API request
        let session = URLSession.shared
        session.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
                return
            }

            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(decodedResponse, nil, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completionHandler(nil, nil, "Failed to decode response: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
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
