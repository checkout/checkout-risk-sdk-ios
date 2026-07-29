//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public final class Risk {
    private let internalConfig: RiskSDKInternalConfig
    private var timer: Timer?
    private var blockTime: Double?
    var fingerprintTimeoutInterval: Double = 3.00

    var loggerService: LoggerServiceProtocol
    var deviceDataService: DeviceDataServiceProtocol
    var fingerprintService: FingerprintServiceProtocol?
    var simpleService: SimpleServiceProtocol?

    public init(config: RiskConfig) {
        internalConfig = RiskSDKInternalConfig(config: config)
        loggerService = LoggerService(internalConfig: internalConfig)
        deviceDataService = DeviceDataService(config: internalConfig, loggerService: loggerService)
    }

    public func configure(completion: @escaping (Result<Void, RiskError.Configuration>) -> Void) {
        deviceDataService.getConfiguration { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let configuration):
                blockTime = configuration.blockTime

                // A collector is enabled when its name is present in `data_collectors`.
                // The PRO collector additionally needs a fingerprint public key.
                if configuration.proEnabled, let fingerprintPublicKey = configuration.fingerprintPublicKey {
                    self.fingerprintService = FingerprintService(
                        fingerprintPublicKey: fingerprintPublicKey,
                        internalConfig: self.internalConfig,
                        loggerService: self.loggerService,
                        blockTime: configuration.blockTime
                    )
                }

                if configuration.simpleEnabled {
                    self.simpleService = SimpleService(
                        dropFieldPaths: configuration.simpleConfig?.dropFieldPaths ?? [],
                        timeoutMs: configuration.simpleConfig?.timeoutMs
                    )
                }

                completion(.success(()))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func publishData(cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError.Publish>) -> Void) {
        guard fingerprintService != nil || simpleService != nil else {
            completion(.failure(.fingerprintServiceIsNotConfigured))
            return
        }

        DispatchQueue.main.async {
            // Timer setup remains on the main queue
            self.timer = Timer.scheduledTimer(withTimeInterval: self.fingerprintTimeoutInterval, repeats: false) { [weak self] _ in // 3.00
                guard let self else { return }

                self.loggerService.log(riskEvent: .publishFailure, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: self.fingerprintService?.fpLoadTime, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "publishData", message: RiskError.Publish.fingerprintTimeout.localizedDescription, status: nil, type: "Timeout"), deviceCollectorProviders: nil)
                completion(.failure(.fingerprintTimeout))
            }
        }

        // Run every enabled collector concurrently; the group only completes once the
        // slowest collector has finished. One collector failing does not prevent the
        // others from publishing.
        let group = DispatchGroup()
        var proResult: Result<FpPublishData, RiskError.Publish>?
        var simpleResult: Result<SimplePublishData, RiskError.Publish>?

        if let fingerprintService {
            group.enter()
            fingerprintService.publishData { result in
                proResult = result
                group.leave()
            }
        }

        if let simpleService {
            group.enter()
            simpleService.publishData { result in
                simpleResult = result
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }

            guard let timer = self.timer, timer.isValid else { // already timed out
                return
            }

            // Timer invalidation remains on the main queue
            self.timer?.invalidate()
            self.timer = nil

            var collectors: [CollectorData] = []
            var providers: [String] = []
            var proRequestId: String?
            var simpleRequestId: String?
            var fpLoadTime = 0.00
            var fpPublishTime = 0.00

            if case .success(let response)? = proResult {
                proRequestId = response.requestId
                fpLoadTime = response.fpLoadTime
                fpPublishTime = response.fpPublishTime
                collectors.append(CollectorData(collector: DeviceCollector.fingerprint.collectorName, sealedResult: nil))
                providers.append(DeviceCollector.fingerprint.collectorName)
            }

            if case .success(let response)? = simpleResult {
                simpleRequestId = response.requestId
                collectors.append(CollectorData(collector: DeviceCollector.simple.collectorName, sealedResult: response.sealedResult))
                providers.append(DeviceCollector.simple.collectorName)
            }

            guard !collectors.isEmpty else {
                // Every enabled collector failed; the failures are already logged by the services.
                completion(.failure(.couldNotPublishRiskData))
                return
            }

            // The backend keys device data on fp_request_id. PRO provides one; when only the
            // simple collector ran there is no server-side request id, so reuse the client-generated
            // id embedded in the simple collector's sealed_result payload.
            let requestId = resolveRequestId(proRequestId: proRequestId, simpleRequestId: simpleRequestId)

            self.loggerService.log(riskEvent: .collected, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, deviceSessionId: nil, requestId: requestId, error: nil, deviceCollectorProviders: providers)

            self.persistFpData(cardToken: cardToken, fingerprintRequestId: requestId, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, collectors: collectors, deviceCollectorProviders: providers, completion: completion)
        }
    }

    private func persistFpData(cardToken: String?, fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, collectors: [CollectorData], deviceCollectorProviders: [String], completion: @escaping (Result<PublishRiskData, RiskError.Publish>) -> Void) {
        self.deviceDataService.persistFpData(fingerprintRequestId: fingerprintRequestId, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, cardToken: cardToken, collectors: collectors, deviceCollectorProviders: deviceCollectorProviders) { result in
            switch result {
            case .success(let response):
                completion(.success(PublishRiskData(deviceSessionId: response.deviceSessionId)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

/// Resolves the root `fp_request_id`. The PRO collector's server-side id wins; otherwise the
/// simple collector's client-generated id (which matches the one embedded in its sealed_result)
/// is used; failing both, a fresh id is generated.
func resolveRequestId(proRequestId: String?, simpleRequestId: String?) -> String {
    proRequestId ?? simpleRequestId ?? UUID().uuidString
}
