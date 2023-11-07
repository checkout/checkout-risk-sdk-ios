//
//  APIServiceTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import Risk

class APIServiceTests: XCTestCase {
    func testAPIServiceWithValidData() {
        let apiService = APIService()
        let validEndpoint = "https://prism-qa.ckotech.co/collect/configuration?integrationType=RiskIosStandalone"
        let validAuthToken = "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo"

        let expectation = self.expectation(description: "API request completed")

        apiService.getJSONFromAPIWithAuthorization(endpoint: validEndpoint, authToken: validAuthToken, responseType: DeviceDataConfiguration.self) { result in
            switch result {
            case .success(let decodedData):
                XCTAssertTrue(decodedData.fingerprintIntegration.enabled)
                XCTAssertNotNil(decodedData.fingerprintIntegration.publicKey)
            case .failure(let error):
                XCTFail("API request failed with error: \(error)")
            }
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAPIServiceWithInvalidEndpoint() {
        let apiService = APIService()
        let invalidEndpoint = "invalidURL"
        let validAuthToken = "yourAuthToken"
        
        let expectation = self.expectation(description: "API request completed")

        apiService.getJSONFromAPIWithAuthorization(endpoint: invalidEndpoint, authToken: validAuthToken, responseType: DeviceDataConfiguration.self) { result in
            switch result {
            case .success:
                XCTFail("API request should have failed due to an invalid endpoint.")
            case .failure(let error):
                XCTAssertTrue(error is NSError)
            }
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
