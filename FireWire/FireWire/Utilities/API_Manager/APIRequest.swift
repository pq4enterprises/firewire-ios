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
        noAuth: Bool = false,
        retryOnAuthFailure: Bool = true,
        completionHandler: @escaping DataCompletionBlock
    ) {
        var urlString = APIEndpoints.baseURL + (apiEndPoint ?? "")
        var accessToken = FWUserDefaults().userToken

        if noAuth {
            accessToken = ""
        }

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
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completionHandler(response, nil, nil)
                case .failure(let error as APIError) where error == .tokenExpired:
                    // Handle token refresh
                    if retryOnAuthFailure {
                        self.refreshToken { success in
                            if success {
                                // Retry original call once
                                self.callApi(
                                    apiEndPoint: apiEndPoint,
                                    payload: payload,
                                    expect: expect,
                                    requestType: requestType,
                                    noAuth: noAuth,
                                    retryOnAuthFailure: false, // Prevent infinite loop
                                    completionHandler: completionHandler
                                )
                            } else {
                                NotificationCenter.default.post(name: .sessionExpired, object: nil)
                                completionHandler(nil, nil, nil)
                            }
                        }
                    } else {
                        completionHandler(nil, nil, error.localizedDescription)
                    }
                case .failure(let error):
                    guard let apiError = error as? APIError else { return }
                    completionHandler(nil, nil, apiError.localizedDescription)
                }
            }
        }
    }

    private func refreshToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = FWUserDefaults().refreshToken else { return }
        let payload = APIPayload.refreshToken(refreshToken: refreshToken).toDictionary()

        self.callApi(
            apiEndPoint: APIEndpoints.refreshToken,
            payload: payload,
            expect: LoginApiResponse.self,
            noAuth: false,
            retryOnAuthFailure: false
        ) { response, _, error in
            guard let loginResponse = response as? LoginApiResponse,
                  let loginData = loginResponse.data,
                  error == nil
            else {
                completion(false)
                return
            }

            // Save new tokens
            FWUserDefaults.setStringForKey(key: .userIDKey, value: loginData.id)
            let userName = "\(loginData.firstName ?? "") \(loginData.lastName ?? "")"
            FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
            FWUserDefaults.setStringForKey(key: .userEmailKey, value: loginData.email)
            FWUserDefaults.setStringForKey(key: .userTokenKey, value: loginData.token)
            FWUserDefaults.setStringForKey(key: .refreshTokenKey, value: loginData.refreshToken)
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: loginData.role)

            completion(true)
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
            let uniqueFileName = "image-\(timestamp).jpg"

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
