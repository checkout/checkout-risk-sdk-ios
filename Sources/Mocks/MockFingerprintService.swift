//
//  MockFingerprintService.swift
//  
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation

class MockFingerprintService: FingerprintServiceProtocol {
    var shouldSucceed: Bool = true
    var requestID: String?

    func publishData(completion: @escaping (Result<String, RiskError>) -> Void) {
        if shouldSucceed {
            if let requestID = requestID {
                completion(.success(requestID))
            } else {
                let fakeRequestID = "fakeRequestID"
                completion(.success(fakeRequestID))
            }
        } else {
            let error = RiskError.description("Mocked publishData error")
            completion(.failure(error))
        }
    }
}
