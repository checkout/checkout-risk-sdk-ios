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

struct LoggerService {
    private let internalConfig: RiskSDKInternalConfig
    private let logger: CheckoutEventLogging
    
    init(internalConfig: RiskSDKInternalConfig) {
        self.internalConfig = internalConfig
        self.logger = CheckoutEventLogger(productName: Constants.productName)
        setup()
    }
    
    func setup() {
        
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
        //        logger.enableLocalProcessor(monitoringLevel: .debug)
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
        
        var monitoringLevel: MonitoringLevel
        let properties: [String: AnyCodable]
        
        switch riskEvent {
        case .published, .collected:
            monitoringLevel = .info
            properties = [
                "EventType": AnyCodable(riskEvent.rawValue),
                "FramesMode": AnyCodable(internalConfig.framesMode),
                "ddTags": AnyCodable("team:prism,service:prism.risk.ios,version:\(Constants.version),env:\(internalConfig.environment.rawValue)"),
                "deviceSessionId": AnyCodable(deviceSessionID),
                "requestID": AnyCodable(requestID),
                "MaskedPublicKey": AnyCodable(getMaskedPublicKey())
            ]
        case .publishFailure, .loadFailure:
            monitoringLevel = .error
            properties = [
                "EventType": AnyCodable(riskEvent.rawValue),
                "FramesMode": AnyCodable(internalConfig.framesMode),
                "ErrorMessage": AnyCodable(error?.message),
                "ErrorType": AnyCodable(error?.type),
                "ErrorReason": AnyCodable(error?.reason)
            ]
        case .publishDisabled:
            monitoringLevel = .warn
            properties = [
                "EventType": AnyCodable(riskEvent.rawValue),
                "FramesMode": AnyCodable(internalConfig.framesMode),
                "ErrorMessage": AnyCodable(error?.message),
                "ErrorType": AnyCodable(error?.type),
                "ErrorReason": AnyCodable(error?.reason)
            ]
        }
        //#if DEBUG
        //        monitoringLevel = .debug
        //#endif
        
        logger.log(event: Event(
            typeIdentifier: "com.checkout.risk-mobile-sdk",
            time: Date(),
            monitoringLevel: monitoringLevel,
            properties: properties
        ))
    }
    
    
    private func getMaskedPublicKey() -> String {
        return String(internalConfig.merchantPublicKey.prefix(8) + "********" + internalConfig.merchantPublicKey.suffix(6))
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
