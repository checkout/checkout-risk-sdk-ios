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
    
    // TODO: Update CI to pass environment variable
    // func testAPIServiceWithValidData() {
    //     let apiService = APIService()
    //     let validEndpoint = "https://prism-qa.ckotech.co/collect/configuration?integrationType=RiskIosStandalone"
        
    //     guard let publicKey = ProcessInfo.processInfo.environment["SAMPLE_MERCHANT_PUBLIC_KEY"] else {
    //         XCTFail("Environment variable SAMPLE_MERCHANT_PUBLIC_KEY is not set.")
    //         return
    //     }

    //     let expectation = self.expectation(description: "API request completed")

    //     apiService.getJSONFromAPIWithAuthorization(endpoint: validEndpoint, authToken: publicKey, responseType: DeviceDataConfiguration.self) { result in
    //         switch result {
    //         case .success(let decodedData):
    //             XCTAssertTrue(decodedData.fingerprintIntegration.enabled)
    //             XCTAssertNotNil(decodedData.fingerprintIntegration.publicKey)
    //         case .failure(let error):
    //             XCTFail("API request failed with error: \(error)")
    //         }

    //         expectation.fulfill()
    //     }

    //     waitForExpectations(timeout: 5, handler: nil)
    // }

    func testAPIServiceWithInvalidEndpoint() {
        let apiService = APIService()
        let invalidEndpoint = "invalidURL"
        let publicKey = "invalid_public_key"

        let expectation = self.expectation(description: "API request completed")

        apiService.getJSONFromAPIWithAuthorization(endpoint: invalidEndpoint, authToken: publicKey, responseType: DeviceDataConfiguration.self) { result in
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
