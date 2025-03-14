//
//  MockFingerprintService.swift
//  
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation
@testable import RiskSDK

class MockFingerprintService: FingerprintServiceProtocol {
    var fpLoadTime: Double = 0.0
    
    var shouldSucceed: Bool = true
    var requestId: String?
    var delayTime: TimeInterval = 0.00

    func publishData(completion: @escaping (Result<FpPublishData, RiskError.Publish>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
        
            if self.shouldSucceed {
                if let requestId = self.requestId {
                    completion(.success(FpPublishData(requestId: requestId, fpLoadTime: 123.00, fpPublishTime: 321.00)))
                } else {
                    let fakeRequestId = "fakeRequestId"
                    completion(.success(FpPublishData(requestId: fakeRequestId, fpLoadTime: 123.00, fpPublishTime: 321.00)))
                }
            } else {
                completion(.failure(.couldNotPublishRiskData))
            }
        }
    }
}
