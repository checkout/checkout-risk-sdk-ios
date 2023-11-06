//
//  RiskTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import XCTest
@testable import Risk

class RiskTests: XCTestCase {
    
    func testCreateInstanceWithValidConfiguration() {
        // Arrange
        let expectation = self.expectation(description: "Risk instance creation")
        var createdRiskInstance: Risk?
        
        let validConfig = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
        
        // Act
        Risk.createInstance(config: validConfig) { risk in
            createdRiskInstance = risk
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotNil(createdRiskInstance)
    }
    
    func testCreateInstanceWithInvalidPublicKey() {
        // Arrange
        let expectation = self.expectation(description: "Risk instance creation with invalid public key")
        var createdRiskInstance: Risk?
        
        let invalidConfig = RiskConfig(publicKey: "invalid_public_key", environment: RiskEnvironment.qa)
        
        // Act
        Risk.createInstance(config: invalidConfig) { risk in
            createdRiskInstance = risk
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(createdRiskInstance)
    }
}
