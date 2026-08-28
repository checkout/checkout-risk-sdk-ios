//
//  MockAPIService.swift
//
//
//  Created by Precious Ossai on 27/11/2023.
//

import Foundation
@testable import RiskSDK

class MockAPIService: APIServiceProtocol {
    var expectedResult: Result<DeviceDataConfiguration, Error>?

    /// Endpoint of the most recent GET. Captured because the endpoint path is otherwise
    /// untestable: a typo in `/collect/configurations` breaks every device session in production
    /// and no assertion would fail.
    var lastGetEndpoint: String?

    /// Endpoint and JSON-encoded body of the most recent PUT, for the same reason — plus it makes
    /// the `collectors` / `sealed_result` wire shape assertable.
    var lastPutEndpoint: String?
    var lastPutBody: Data?

    func getJSONFromAPIWithAuthorization<T>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        lastGetEndpoint = endpoint
        if let expectedResult = expectedResult as? Result<T, Error> {
            completion(expectedResult)
        }
    }

    var expectedDeviceDataResult: Result<PersistDeviceDataResponse, Error>?
    func putDataToAPIWithAuthorization<T, U>(endpoint: String, authToken: String, data: T, responseType: U.Type, completion: @escaping (Result<U, Error>) -> Void) where T: Encodable, U: Decodable {
        lastPutEndpoint = endpoint
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        lastPutBody = try? encoder.encode(data)
        if let expectedResult = expectedDeviceDataResult as? Result<U, Error> {
            completion(expectedResult)
        }
    }
}
