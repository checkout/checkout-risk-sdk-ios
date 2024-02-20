//
//  MockAPIService.swift
//
//
//  Created by Precious Ossai on 27/11/2023.
//

import Foundation

class MockAPIService: APIServiceProtocol {
    var expectedResult: Result<DeviceDataConfiguration, Error>?

    func getJSONFromAPIWithAuthorization<T>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        if let expectedResult = expectedResult as? Result<T, Error> {
            completion(expectedResult)
        }
    }

    var expectedDeviceDataResult: Result<PersistDeviceDataResponse, Error>?
    func putDataToAPIWithAuthorization<T, U>(endpoint: String, authToken: String, data: T, responseType: U.Type, completion: @escaping (Result<U, Error>) -> Void) where T: Encodable, U: Decodable {
        if let expectedResult = expectedDeviceDataResult as? Result<U, Error> {
            completion(expectedResult)
        }
    }
}
