//
//  MockFingerprintService.swift
//  
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation
@testable import Risk

class MockFingerprintService: FingerprintServiceProtocol {
    var shouldSucceed: Bool = true
    var requestId: String?

    func publishData(completion: @escaping (Result<FpPublishData, RiskError.Publish>) -> Void) {
        if shouldSucceed {
            if let requestId = requestId {
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
