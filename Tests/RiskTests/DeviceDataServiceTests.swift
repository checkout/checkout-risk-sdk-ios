//
//  DeviceDataServiceTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import Risk // Replace with the actual name of your module

class DeviceDataServiceTests: XCTestCase {
    func testGetConfiguration() {
        // Mocking your APIService to provide expected results for testing
        let mockAPIService = MockAPIService()
        
        // Create a DeviceDataService with a mocked configuration
        let config = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService)
        
        // Create an expectation for the async completion handler
        let expectation = self.expectation(description: "Configuration received")
        
        // Define the expected configuration
        let expectedConfiguration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mockPublicKey"))
        
        // Set up the mockAPIService to return the expected configuration
        mockAPIService.expectedResult = .success(expectedConfiguration)
        
        // Call the getConfiguration method
        deviceDataService.getConfiguration { configuration in
            // Check if the received configuration matches the expected configuration
            XCTAssertEqual(configuration, expectedConfiguration)
            
            // Fulfill the expectation to indicate that the completion handler was called
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled within a certain time frame
        waitForExpectations(timeout: 5, handler: nil)
    }
}


// Mock APIService for testing purposes
class MockAPIService: APIServiceProtocol {
    var expectedResult: Result<DeviceDataConfiguration, Error>?
    
    func getJSONFromAPIWithAuthorization<T>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        if let expectedResult = expectedResult as? Result<T, Error> {
            completion(expectedResult)
        }
    }
}
