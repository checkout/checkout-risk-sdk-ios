//
//  MockSimpleService.swift
//
//
//  Mock for the open-source `simple` collector service.
//

import Foundation
@testable import RiskSDK

class MockSimpleService: SimpleServiceProtocol {
    var shouldSucceed: Bool = true
    var requestId: String?
    var sealedResult: String = "mocked_sealed_result"
    var delayTime: TimeInterval = 0.00

    func publishData(completion: @escaping (Result<SimplePublishData, RiskError.Publish>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            if self.shouldSucceed {
                let id = self.requestId ?? "mocked_simple_request_id"
                completion(.success(SimplePublishData(deviceId: id, requestId: id, sealedResult: self.sealedResult)))
            } else {
                completion(.failure(.couldNotPublishRiskData))
            }
        }
    }
}
