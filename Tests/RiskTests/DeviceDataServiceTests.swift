//
//  DeviceDataServiceTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import Risk

class DeviceDataServiceTests: XCTestCase {
    func testGetConfiguration() {
        let mockAPIService = MockAPIService()
        
        let config = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService)
        
        let expectation = self.expectation(description: "Configuration received")
        
        let expectedConfiguration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mockPublicKey"))
        
        mockAPIService.expectedResult = .success(expectedConfiguration)
        
        deviceDataService.getConfiguration { configuration in
            XCTAssertEqual(configuration, expectedConfiguration)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}


class MockAPIService: APIServiceProtocol {
    var expectedResult: Result<DeviceDataConfiguration, Error>?
    
    func getJSONFromAPIWithAuthorization<T>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        if let expectedResult = expectedResult as? Result<T, Error> {
            completion(expectedResult)
        }
    }
}
