//
//  LoggerService.swift
//
//
//  Created by Precious Ossai on 21/11/2023.
//

import Foundation
import CheckoutEventLoggerKit
import UIKit

enum RiskEvent: String, Codable {
    case publishDisabled = "riskDataPublishDisabled"
    case published = "riskDataPublished"
    case publishFailure = "riskDataPublishFailure"
    case collected = "riskDataCollected"
    case loadFailure = "riskLoadFailure"
}

struct Elapsed {
    let block: Double? // time to retrieve configuration or loadFailure
    let deviceDataPersist: Double? // time to persist data
    let fpload: Double? // time to load fingerprint
    let fppublish: Double? // time to publish fingerprint data
    let total: Double? // total time

    private enum CodingKeys: String, CodingKey {
        case block = "Block", deviceDataPersist = "DeviceDataPersist", fpload = "FpLoad", fppublish = "FpPublish", total = "Total"
    }
}

struct RiskLogError {
    let reason: String // service method
    let message: String // description of error
    let status: Int? // status code
    let type: String? // Error type

    private enum CodingKeys: String, CodingKey {
        case reason = "Reason", message = "Message", status = "Status", type = "Type"
    }
}

protocol LoggerServiceProtocol {
    init(internalConfig: RiskSDKInternalConfig)
    func log(riskEvent: RiskEvent, blockTime: Double?, deviceDataPersistTime: Double?, fpLoadTime: Double?, fpPublishTime: Double?, deviceSessionId: String?, requestId: String?, error: RiskLogError?)
}

extension LoggerServiceProtocol {
    func formatEvent(internalConfig: RiskSDKInternalConfig, riskEvent: RiskEvent, deviceSessionId: String?, requestId: String?, error: RiskLogError?, latencyMetric: Elapsed) -> Event {
        let maskedPublicKey = getMaskedPublicKey(publicKey: internalConfig.merchantPublicKey)
        let ddTags = getDDTags(environment: internalConfig.environment.rawValue)
        var monitoringLevel: MonitoringLevel
        let framesMode = internalConfig.framesOptions != nil
        let properties: [String: AnyCodable]

        switch riskEvent {
        case .published, .collected:
            monitoringLevel = .info
        case .publishFailure, .loadFailure:
            monitoringLevel = .error
        case .publishDisabled:
            monitoringLevel = .warn
        }

        #if DEBUG
        monitoringLevel = .debug
        #endif

        switch riskEvent {
        case .published, .collected:
            properties = [
                "Block": AnyCodable(latencyMetric.block),
                "DeviceDataPersist": AnyCodable(latencyMetric.deviceDataPersist),
                "FpLoad": AnyCodable(latencyMetric.fpload),
                "FpPublish": AnyCodable(latencyMetric.fppublish),
                "Total": AnyCodable(latencyMetric.total),
                "EventType": AnyCodable(riskEvent.rawValue),
                "FramesMode": AnyCodable(framesMode),
                "MaskedPublicKey": AnyCodable(maskedPublicKey),
                "ddTags": AnyCodable(ddTags),
                "RiskSDKVersion": AnyCodable(Constants.riskSdkVersion),
                "Timezone": AnyCodable(TimeZone.current.identifier),
                "FpRequestId": AnyCodable(requestId),
                "DeviceSessionId": AnyCodable(deviceSessionId),
            ]
        case .publishFailure, .loadFailure, .publishDisabled:
            properties = [
                "Block": AnyCodable(latencyMetric.block),
                "DeviceDataPersist": AnyCodable(latencyMetric.deviceDataPersist),
                "FpLoad": AnyCodable(latencyMetric.fpload),
                "FpPublish": AnyCodable(latencyMetric.fppublish),
                "Total": AnyCodable(latencyMetric.total),
                "EventType": AnyCodable(riskEvent.rawValue),
                "FramesMode": AnyCodable(framesMode),
                "MaskedPublicKey": AnyCodable(maskedPublicKey),
                "ddTags": AnyCodable(ddTags),
                "RiskSDKVersion": AnyCodable(Constants.riskSdkVersion),
                "Timezone": AnyCodable(TimeZone.current.identifier),
                "ErrorMessage": AnyCodable(error?.message),
                "ErrorType": AnyCodable(error?.type),
                "ErrorReason": AnyCodable(error?.reason),
            ]
        }

        return Event(
            typeIdentifier: riskEvent.rawValue,
            time: Date(),
            monitoringLevel: monitoringLevel,
            properties: properties
        )
    }

    func getMaskedPublicKey (publicKey: String) -> String {
        return "\(publicKey.prefix(8))********\(publicKey.suffix(6))"
    }

    func getDDTags(environment: String) -> String {
        return "team:prism,service:prism.risk.ios,version:\(Constants.riskSdkVersion),env:\(environment)"
    }
}

struct LoggerService: LoggerServiceProtocol {
    private let internalConfig: RiskSDKInternalConfig
    private let logger: CheckoutEventLogging

    init(internalConfig: RiskSDKInternalConfig) {
        self.internalConfig = internalConfig
        self.logger = CheckoutEventLogger(productName: Constants.productName)
        setup()
    }

    private func setup() {
        let logEnvironment: Environment
        let productIdentifier = internalConfig.framesOptions?.productIdentifier ?? Constants.productName
        let productVersion = internalConfig.framesOptions?.version ?? Constants.riskSdkVersion

        switch internalConfig.environment {
        case .qa, .sandbox:
            logEnvironment = .sandbox
        case .production:
            logEnvironment = .production
        }

        #if DEBUG
        logger.enableLocalProcessor(monitoringLevel: .debug)
        #endif

        logger.enableRemoteProcessor(
            environment: logEnvironment,
            remoteProcessorMetadata: RemoteProcessorMetadata(
                productIdentifier: productIdentifier,
                productVersion: productVersion,
                environment: internalConfig.environment.rawValue
            )
        )
    }

    func log(riskEvent: RiskEvent, blockTime: Double? = nil, deviceDataPersistTime: Double? = nil, fpLoadTime: Double? = nil, fpPublishTime: Double? = nil, deviceSessionId: String? = nil, requestId: String? = nil, error: RiskLogError? = nil) {
        
        let totalLatency = (blockTime ?? 0.00) + (deviceDataPersistTime ?? 0.00) + (fpLoadTime ?? 0.00) + (fpPublishTime ?? 0.00)
        
        let latencyMetric = Elapsed(block: blockTime, deviceDataPersist: deviceDataPersistTime, fpload: fpLoadTime, fppublish: fpPublishTime, total: totalLatency)
        
        let event = formatEvent(internalConfig: internalConfig, riskEvent: riskEvent, deviceSessionId: deviceSessionId, requestId: requestId, error: error, latencyMetric: latencyMetric)
        logger.log(event: event)
    }
}
