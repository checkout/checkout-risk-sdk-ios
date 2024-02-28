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

    func publishData(completion: @escaping (Result<String, RiskError.Publish>) -> Void) {
        if shouldSucceed {
            if let requestId = requestId {
                completion(.success(requestId))
            } else {
                let fakeRequestId = "fakeRequestId"
                completion(.success(fakeRequestId))
            }
        } else {
            completion(.failure(.couldNotPublishRiskData))
        }
    }
}
