//
//  ApiService.swift
//  RiskIos
//  Sources
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation

protocol ApiServiceProtocol: AnyObject {
    func getJSONFromAPIWithAuthorization<T: Decodable>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void)
}

enum APIServiceError: Error {  
   case invalidURL
   case noData
   case httpError(Int)
   
   var localizedDescription: String {  
       switch self {
           case .invalidURL:
               return "Invalid URL"  
           case .noData: 
               return "No Data"
           case .httpError(let code):
               return "HTTP Error: \(code)"
       }  
   }  
}  

final class ApiService: ApiServiceProtocol {
    
    public func getJSONFromAPIWithAuthorization<T: Decodable>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        // Create a URL based on the endpoint string
        guard let url = URL(string: endpoint) else {
            completion(.failure(APIServiceError.invalidURL))
            return
        }
        
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
                completion(.failure(APIServiceError.httpError((response as? HTTPURLResponse)?.statusCode ?? 500)))
                return
            }
            
            // Check if we have data
            guard let data = data else {
                completion(.failure(APIServiceError.noData))
                return
            }
            
            do {
                // Use JSONDecoder to decode the JSON data
                let decoder = JSONDecoder()
                // Set the keyDecodingStrategy to convert snake_case to camelCase if needed
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }
        
        // Start the data task
        task.resume()
    }
}
