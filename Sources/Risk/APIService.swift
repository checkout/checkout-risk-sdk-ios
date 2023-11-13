//
//  APIService.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation

protocol APIServiceProtocol {
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

struct APIService: APIServiceProtocol {
    
    func getJSONFromAPIWithAuthorization<T: Decodable>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(APIServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIServiceError.httpError((response as? HTTPURLResponse)?.statusCode ?? 500)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIServiceError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
