//
//  LoggerService.swift
//
//
//  Created by Precious Ossai on 21/11/2023.
//

import Foundation

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

final class LoggerService {
    private let internalConfig: RiskSDKInternalConfig
    
    init(internalConfig: RiskSDKInternalConfig) {
        self.internalConfig = internalConfig
    }
    
    func log(riskEvent: RiskEvent, deviceSessionID: String? = nil, requestID: String? = nil) {
        let schema = formatSchema(riskEvent: riskEvent, deviceSessionID: deviceSessionID, requestID: requestID)
        // TODO: Send schema to DataDog with CloudEventsAPI
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
        case .publishFailure:
            logLevel = .error
        }
        
        return CloudEventsPayload(id: randomId, type: riskEvent, time: timeStamp, data: cloudEventsData, cko: CloudEventsCkoTags(ddTags: dataDogTag, logLevel: logLevel))
    }
}
