//
//  DeviceDataService.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation
import QuartzCore

/// Response of the `configurations` endpoint. `dataCollectors` lists the collectors
/// enabled for the merchant (e.g. "fingerprint", "simple"); a collector is considered
/// enabled when its name is present in this list.
struct DeviceDataConfiguration: Decodable, Equatable {
    let dataCollectors: [String]
    let publicKey: String?
    let simple: SimpleCollectorConfig?

    private enum CodingKeys: String, CodingKey {
        case dataCollectors, publicKey, simple
    }

    init(dataCollectors: [String] = [], publicKey: String? = nil, simple: SimpleCollectorConfig? = nil) {
        self.dataCollectors = dataCollectors
        self.publicKey = publicKey
        self.simple = simple
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataCollectors = try container.decodeIfPresent([String].self, forKey: .dataCollectors) ?? []
        publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey)
        simple = try container.decodeIfPresent(SimpleCollectorConfig.self, forKey: .simple)
    }
}

/// Per-collector configuration for the `simple` collector.
///
/// - `dropFieldPaths`: dot-notation paths into the collected `device` data that must be
///   removed before the payload is base64-encoded (e.g. "canvas.value.geometry").
/// - `timeoutMs`: collection timeout budget in milliseconds.
struct SimpleCollectorConfig: Decodable, Equatable {
    let dropFieldPaths: [String]
    let timeoutMs: Int?

    private enum CodingKeys: String, CodingKey {
        case dropFieldPaths, timeoutMs
    }

    init(dropFieldPaths: [String] = [], timeoutMs: Int? = nil) {
        self.dropFieldPaths = dropFieldPaths
        self.timeoutMs = timeoutMs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dropFieldPaths = try container.decodeIfPresent([String].self, forKey: .dropFieldPaths) ?? []
        timeoutMs = try container.decodeIfPresent(Int.self, forKey: .timeoutMs)
    }
}

/// The resolved device data configuration used by the SDK once the enabled collectors
/// have been determined from the `configurations` response.
struct DeviceDataConfig: Equatable {
    let fingerprintPublicKey: String?
    let simpleConfig: SimpleCollectorConfig?
    let proEnabled: Bool
    let simpleEnabled: Bool
    let blockTime: Double
}

/// A single collector's contribution to the publish payload. The backend derives the
/// `device_collector_provider` recorded on prism_events from `collector`.
///
/// For the PRO collector the raw identifier travels in the root `fp_request_id`, so
/// `sealedResult` is nil. For the open-source `simple` collector the collected device
/// data (device id plus raw signals) is JSON-serialised and base64-encoded into `sealedResult`.
struct CollectorData: Codable, Equatable {
    let collector: String
    let sealedResult: String?

    private enum CodingKeys: String, CodingKey {
        case collector, sealedResult
    }
}

struct PersistDeviceDataServiceData: Codable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case integrationType, fingerprintRequestId = "fpRequestId", cardToken, collectors
    }

    let integrationType: RiskIntegrationType
    let fingerprintRequestId: String
    let cardToken: String?
    let collectors: [CollectorData]
}

struct PersistDeviceDataResponse: Decodable, Equatable {
    let deviceSessionId: String

    private enum CodingKeys: String, CodingKey {
        case deviceSessionId = "deviceSessionId"
    }
}

protocol DeviceDataServiceProtocol {
    func getConfiguration(completion: @escaping (Result<DeviceDataConfig, RiskError.Configuration>) -> Void)
    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, collectors: [CollectorData], deviceCollectorProviders: [String], completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void)
}

final class DeviceDataService: DeviceDataServiceProtocol {
    let config: RiskSDKInternalConfig
    let apiService: APIServiceProtocol
    let loggerService: LoggerServiceProtocol
    var blockTime: Double

    init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService(), loggerService: LoggerServiceProtocol) {
        self.config = config
        self.apiService = apiService
        self.loggerService = loggerService
        self.blockTime = 0.00
    }

    func getConfiguration(completion: @escaping (Result<DeviceDataConfig, RiskError.Configuration>) -> Void) {
        let startBlockTime = CACurrentMediaTime()
        let endpoint = "\(config.deviceDataEndpoint)/configurations?integrationType=\(config.integrationType.rawValue)&riskSdkVersion=\(Constants.riskSdkVersion)&timezone=\(TimeZone.current.identifier)"
        let authToken = config.merchantPublicKey

        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                let endBlockTime = CACurrentMediaTime()
                self.blockTime = (endBlockTime - startBlockTime) * 1000

                // A collector is enabled when its name is present in `data_collectors`.
                // The PRO collector additionally needs a fingerprint public key.
                let proEnabled = configuration.dataCollectors.contains(DeviceCollector.fingerprint.collectorName)
                    && configuration.publicKey != nil
                let simpleEnabled = configuration.dataCollectors.contains(DeviceCollector.simple.collectorName)

                guard proEnabled || simpleEnabled else {
                    self.loggerService.log(riskEvent: .publishDisabled, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: nil, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: RiskError.Configuration.integrationDisabled.localizedDescription, status: nil, type: "Error"), deviceCollectorProviders: nil)

                    return completion(.failure(.integrationDisabled))
                }

                completion(.success(
                    DeviceDataConfig(
                        fingerprintPublicKey: configuration.publicKey,
                        simpleConfig: configuration.simple,
                        proEnabled: proEnabled,
                        simpleEnabled: simpleEnabled,
                        blockTime: self.blockTime
                    )))
            case .failure(let error):
                self.loggerService.log(riskEvent: .loadFailure, blockTime: nil, deviceDataPersistTime: nil, fpLoadTime: nil, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: error.localizedDescription, status: nil, type: "Error"), deviceCollectorProviders: nil)
                return completion(.failure(.couldNotRetrieveConfiguration))
            }
        }
    }

    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, collectors: [CollectorData], deviceCollectorProviders: [String], completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void) {
        let startPersistTime = CACurrentMediaTime()
        let endpoint = "\(config.deviceDataEndpoint)/fingerprint/v2?riskSdkVersion=\(Constants.riskSdkVersion)"
        let authToken = config.merchantPublicKey
        let integrationType = config.integrationType

        let data = PersistDeviceDataServiceData(
            integrationType: integrationType,
            fingerprintRequestId: fingerprintRequestId,
            cardToken: cardToken,
            collectors: collectors
        )

        apiService.putDataToAPIWithAuthorization(endpoint: endpoint, authToken: authToken, data: data, responseType: PersistDeviceDataResponse.self) { result in

            switch result {
            case .success(let response):
                let endPersistTime = CACurrentMediaTime()
                let persistTime = (endPersistTime - startPersistTime) * 1000
                self.loggerService.log(riskEvent: .published, blockTime: self.blockTime, deviceDataPersistTime: persistTime, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, deviceSessionId: response.deviceSessionId, requestId: fingerprintRequestId, error: nil, deviceCollectorProviders: deviceCollectorProviders)

                completion(.success(response))
            case .failure(let error):
                self.loggerService.log(riskEvent: .publishFailure, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "persistFpData", message: error.localizedDescription, status: nil, type: "Error"), deviceCollectorProviders: deviceCollectorProviders)

                completion(.failure(.couldNotPersisRiskData))
            }
        }
    }
}
