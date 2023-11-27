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

struct RiskLogError {
    let reason: String // service
    let message: String // description of error
    let status: Int? // status code
    let type: String? // TODO: - Add error type, e.g. timeout, Error
    
    private enum CodingKeys: String, CodingKey {
        case reason = "Reason", message = "Message", status = "Status", type = "Type"
    }
}

protocol LoggerServiceProtocol {
    init(internalConfig: RiskSDKInternalConfig)
    func log(riskEvent: RiskEvent, deviceSessionID: String?, requestID: String?, error: RiskLogError?)
}

extension LoggerServiceProtocol {
    func formatEvent(internalConfig: RiskSDKInternalConfig, riskEvent: RiskEvent, deviceSessionID: String?, requestID: String?, error: RiskLogError?) -> Event {
        let maskedPublicKey = internalConfig.merchantPublicKey.prefix(8) + "********" + internalConfig.merchantPublicKey.suffix(6)
        var monitoringLevel: MonitoringLevel
        var properties: [String: AnyCodable] = [
            "EventType": AnyCodable(riskEvent.rawValue),
            "FramesMode": AnyCodable(internalConfig.framesMode),
        ]
        let errorProperties: [String: AnyCodable] = [
            "ErrorMessage": AnyCodable(error?.message),
            "ErrorType": AnyCodable(error?.type),
            "ErrorReason": AnyCodable(error?.reason)
        ]
        let ddProperties: [String: AnyCodable] = [
            "ddTags": AnyCodable("team:prism,service:prism.risk.ios,version:\(Constants.version),env:\(internalConfig.environment.rawValue)"),
            "deviceSessionId": AnyCodable(deviceSessionID),
            "requestID": AnyCodable(requestID),
            "MaskedPublicKey": AnyCodable(maskedPublicKey)
        ]
        
        switch riskEvent {
        case .published, .collected:
            monitoringLevel = .info
            properties.merge(ddProperties) { (_, new) in new }
        case .publishFailure, .loadFailure:
            monitoringLevel = .error
            properties.merge(errorProperties) { (_, new) in new }
        case .publishDisabled:
            monitoringLevel = .warn
            properties.merge(errorProperties) { (_, new) in new }
        }
        
        return Event(
            typeIdentifier: "com.checkout.risk-mobile-sdk",
            time: Date(),
            monitoringLevel: monitoringLevel,
            properties: properties
        )
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
        
        let appBundle = Bundle.main
        let appPackageName = appBundle.bundleIdentifier ?? "unavailableAppPackageName"
        let appPackageVersion = appBundle
            .infoDictionary?["CFBundleShortVersionString"] as? String ?? "unavailableAppPackageVersion"
        
        let deviceName = getDeviceModel()
        let osVersion = UIDevice.current.systemVersion
        let logEnvironment: Environment
        
        switch internalConfig.environment {
        case .qa, .sandbox:
            logEnvironment = .sandbox
        case .prod:
            logEnvironment = .production
        }
        
        //#if DEBUG
        // logger.enableLocalProcessor(monitoringLevel: .debug)
        //#endif
        
        logger.enableRemoteProcessor(
            environment: logEnvironment,
            remoteProcessorMetadata: RemoteProcessorMetadata(
                productIdentifier: Constants.productName,
                productVersion: Constants.version,
                environment: internalConfig.environment.rawValue,
                appPackageName: appPackageName,
                appPackageVersion: appPackageVersion,
                deviceName: deviceName,
                platform: "iOS",
                osVersion: osVersion
            )
        )
        
    }
    
    func log(riskEvent: RiskEvent, deviceSessionID: String? = nil, requestID: String? = nil, error: RiskLogError? = nil) {
        let event = formatEvent(internalConfig: internalConfig, riskEvent: riskEvent, deviceSessionID: deviceSessionID, requestID: requestID, error: error)
        logger.log(event: event)
    }
    
    private func getDeviceModel() -> String {
#if targetEnvironment(simulator)
        if let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return identifier
        }
#endif
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
