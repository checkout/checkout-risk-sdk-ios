//
//  File.swift
//  
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import RiskIos // Replace with the actual name of your module

class DeviceDataServiceTests: XCTestCase {
    func testGetConfiguration() {
        // Mocking your ApiService to provide expected results for testing
        let mockApiService = MockApiService()
        
        // Create a DeviceDataService with a mocked configuration
        let config = RiskIosConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
        let internalConfig = RiskSdkInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig)
        
        // Inject the mock ApiService
        deviceDataService.apiService = mockApiService
        
        // Create an expectation for the async completion handler
        let expectation = self.expectation(description: "Configuration received")
        
        // Define the expected configuration
        let expectedConfiguration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mockPublicKey"))
        
        // Set up the mockApiService to return the expected configuration
        mockApiService.expectedResult = .success(expectedConfiguration)
        
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


// Mock ApiService for testing purposes
class MockApiService: ApiServiceProtocol {
    var expectedResult: Result<DeviceDataConfiguration, Error>?
    
    func getJSONFromAPIWithAuthorization<T>(endpoint: String, authToken: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        if let expectedResult = expectedResult as? Result<T, Error> {
            completion(expectedResult)
        }
    }
}
