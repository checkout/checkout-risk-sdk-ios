//
//  ApiServiceTests.swift
//  RiskIosTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import RiskIos

class ApiServiceTests: XCTestCase {
    func testApiServiceWithValidData() {
        // Arrange
        let apiService = ApiService()
        let validEndpoint = "https://prism-qa.ckotech.co/collect/configuration?integrationType=RiskJsStandalone"
        let validAuthToken = "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo"

        // Create an expectation for the async completion handler
        let expectation = self.expectation(description: "API request completed")

        // Act
        apiService.getJSONFromAPIWithAuthorization(endpoint: validEndpoint, authToken: validAuthToken, responseType: DeviceDataConfiguration.self) { result in
            // Assert
            switch result {
            case .success(let decodedData):
                XCTAssertTrue(decodedData.fingerprintIntegration.enabled)
                XCTAssertNotNil(decodedData.fingerprintIntegration.publicKey)
            case .failure(let error):
                XCTFail("API request failed with error: \(error)")
            }
            
            // Fulfill the expectation to indicate that the completion handler was called
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled within a certain time frame
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testApiServiceWithInvalidEndpoint() {
        // Arrange
        let apiService = ApiService()
        let invalidEndpoint = "invalidURL"
        let validAuthToken = "yourAuthToken"
        
        // Create an expectation for the async completion handler
        let expectation = self.expectation(description: "API request completed")

        // Act
        apiService.getJSONFromAPIWithAuthorization(endpoint: invalidEndpoint, authToken: validAuthToken, responseType: DeviceDataConfiguration.self) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("API request should have failed due to an invalid endpoint.")
            case .failure(let error):
                // You can add specific error assertions here
                XCTAssertTrue(error is NSError)
            }
            
            // Fulfill the expectation to indicate that the completion handler was called
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled within a certain time frame
        waitForExpectations(timeout: 5, handler: nil)
    }
}
