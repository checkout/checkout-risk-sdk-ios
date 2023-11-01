//
//  File.swift
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation

protocol ApiServiceProtocol {
    func getJSONFromAPIWithAuthorization<T: Decodable>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void)
}

final class ApiService: ApiServiceProtocol {
    
    public func getJSONFromAPIWithAuthorization<T: Decodable>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        // Create a URL based on the endpoint string
        if let url = URL(string: endpoint) {
            var request = URLRequest(url: url)
            
            // Set the Authorization header
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Check for errors
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check if we received a response
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "HTTP Error", code: 0, userInfo: nil)))
                    return
                }
                
                // Check if we have data
                guard let data = data else {
                    completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                   // Use JSONDecoder to decode the JSON data
                   let decoder = JSONDecoder()
                   // Set the keyDecodingStrategy to convert snake_case to camelCase if needed
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
                   
                   // Use .allowFragments to parse JSON without a top-level container
                   let decodedData = try decoder.decode(T.self, from: data)
                   completion(.success(decodedData))
               } catch {
                   completion(.failure(error))
               }
            }
            
            // Start the data task
            task.resume()
        } else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        }
    }
}
