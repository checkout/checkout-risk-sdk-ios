//
//  LoggerService.swift
//
//
//  Created by Precious Ossai on 21/11/2023.
//

import Foundation
import CheckoutEventLoggerKit
import UIKit

enum CloudEventsEnvironment {
    case qa
    case sandbox
    case prod
}

enum LogLevel: String {
    case info
    case warning
    case error
}

enum RiskEvent: String, Codable {
    case publishDisabled = "riskDataPublishDisabled"
    case published = "riskDataPublished"
    case publishFailure = "riskDataPublishFailure"
    case collected = "riskDataCollected"
    case loadFailure = "riskLoadFailure"
}

struct CloudEventsProperties: Codable {
    let maskedPublicKey: String
    let framesMode: Bool
    let deviceSessionID: String?
    let requestID: String?
    let eventType: RiskEvent
    
    
    private enum CodingKeys: String, CodingKey {
        case maskedPublicKey = "MaskedPublicKey", framesMode = "FramesMode", deviceSessionID = "DeviceSessionId", requestID = "RequestId", eventType = "EventType"
    }
}

struct CloudEventsData {
    let properties: CloudEventsProperties
}

struct CloudEventsCkoTags {
    let ddTags: String
    let logLevel: LogLevel
}

struct CloudEventsPayload {
    let specversion: String = "1.0"
    let id: String
    let type: RiskEvent
    let source: String = "prism.risk.ios"
    let time: String
    let data: CloudEventsData
    let cko: CloudEventsCkoTags
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
#if DEBUG
        logger.enableLocalProcessor(monitoringLevel: .debug)
#endif
        
        logger.enableRemoteProcessor(
            environment: .sandbox,
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
        let schema = formatSchema(riskEvent: riskEvent, deviceSessionID: deviceSessionID, requestID: requestID)
        
        var monitoringLevel: MonitoringLevel
        let properties: [String: AnyCodable]
        
        switch schema.cko.logLevel {
        case .info:
            monitoringLevel = .info
            properties = ["EventType": AnyCodable(riskEvent.rawValue), "deviceSessionId": AnyCodable(deviceSessionID), "requestID": AnyCodable(requestID), "MaskedPublicKey": AnyCodable(getMaskedPublicKey())]
        case .error:
            monitoringLevel = .error
            properties = ["EventType": AnyCodable(riskEvent.rawValue), "ErrorMessage": AnyCodable(error?.message), "ErrorType": AnyCodable(error?.type), "ErrorReason": AnyCodable(error?.reason)]
        case .warning:
            monitoringLevel = .warn
            properties = ["EventType": AnyCodable(riskEvent.rawValue), "ErrorMessage": AnyCodable(error?.message), "ErrorType": AnyCodable(error?.type), "ErrorReason": AnyCodable(error?.reason)]
        }
        #if DEBUG
                monitoringLevel = .debug
        #endif
        
        logger.log(event: Event(
            typeIdentifier: "com.checkout.risk-mobile-sdk",
            time: Date(),
            monitoringLevel: monitoringLevel,
            properties: properties
        ))
    }
    
    private func formatSchema(riskEvent: RiskEvent, deviceSessionID: String?, requestID: String?) -> CloudEventsPayload {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let timeStamp = dateFormatter.string(from: Date())
        let randomId = UUID().uuidString
        let maskedPublicKey = String(internalConfig.merchantPublicKey.prefix(8) + "********" + internalConfig.merchantPublicKey.suffix(6))
        let cloudEventsData = CloudEventsData(properties: CloudEventsProperties(maskedPublicKey: maskedPublicKey, framesMode: internalConfig.framesMode, deviceSessionID: deviceSessionID, requestID: requestID, eventType: riskEvent))
        let dataDogTag = "team:prism,service:prism.risk.ios,version:0.1.1,env:\(internalConfig.environment)"
        var logLevel:LogLevel
        
        switch riskEvent {
        case .publishDisabled:
            logLevel = .warning
        case .published, .collected:
            logLevel = .info
        case .publishFailure, .loadFailure:
            logLevel = .error
        }
        
        return CloudEventsPayload(id: randomId, type: riskEvent, time: timeStamp, data: cloudEventsData, cko: CloudEventsCkoTags(ddTags: dataDogTag, logLevel: logLevel))
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
