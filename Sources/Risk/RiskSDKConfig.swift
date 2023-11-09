//
//  RiskSdkConfig.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import FingerprintPro

public enum RiskEnvironment {
    case qa
    case sandbox
    case production
}

enum RiskIntegrationType: String, Encodable {
    case standalone = "RiskIosStandalone"
    case inFrames = "RiskIosInFramesIos"
}

enum RiskEvent {
    case publishDisabled
    case published
    case publishBlocked
    case publishFailure
    case collected
}

enum SourceType: String {
    case cardToken = "card_token"
    case riskSDK = "riskios"
}

public struct RiskConfig {
    public let publicKey: String
    public let environment: RiskEnvironment
    public let framesMode: Bool
    
    public init(publicKey: String, environment: RiskEnvironment, framesMode: Bool = false) {
        self.publicKey = publicKey
        self.environment = environment
        self.framesMode = framesMode
    }
}

struct RiskSDKInternalConfig {
    let merchantPublicKey: String
    let deviceDataEndpoint: String
    let fingerprintEndpoint: String
    let integrationType: RiskIntegrationType.RawValue
    let sourceType: SourceType.RawValue
    
    init(config: RiskConfig) {
        merchantPublicKey = config.publicKey
        integrationType = config.framesMode ? RiskIntegrationType.inFrames.rawValue : RiskIntegrationType.standalone.rawValue
        sourceType = config.framesMode ? SourceType.cardToken.rawValue : SourceType.riskSDK.rawValue
        
        switch config.environment {
        case .qa:
            deviceDataEndpoint = "https://prism-qa.ckotech.co/collect"
            fingerprintEndpoint = "https://fpjs.cko-qa.ckotech.co"
        case .sandbox:
            deviceDataEndpoint = "https://risk.sandbox.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.sandbox.checkout.com"
        case .production:
            deviceDataEndpoint = "https://risk.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.checkout.com"
        }
    }
    
}
