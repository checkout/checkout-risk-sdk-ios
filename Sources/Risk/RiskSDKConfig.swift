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
    case RiskIosStandalone
    case RiskIosInFramesIos
}

enum RiskEvent {
    case publishDisabled
    case published
    case publishBlocked
    case publishFailure
    case collected
}

enum SourceType: String {
    case card_token = "card_token"
    case riskios = "riskios"
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
    let integrationType: RiskIntegrationType
    let sourceType: SourceType
    
    init(config: RiskConfig) {
        self.merchantPublicKey = config.publicKey
        self.integrationType = config.framesMode ? RiskIntegrationType.RiskIosInFramesIos : RiskIntegrationType.RiskIosStandalone
        self.sourceType = config.framesMode ? SourceType.card_token : SourceType.riskios
        
        switch config.environment {
        case .qa:
            self.deviceDataEndpoint = "https://prism-qa.ckotech.co/collect"
            self.fingerprintEndpoint = "https://fpjs.cko-qa.ckotech.co"
        case .sandbox:
            self.deviceDataEndpoint = "https://risk.sandbox.checkout.com/collect"
            self.fingerprintEndpoint = "https://fpjs.sandbox.checkout.com"
        case .production:
            self.deviceDataEndpoint = "https://risk.checkout.com/collect"
            self.fingerprintEndpoint = "https://fpjs.checkout.com"
        }
    }
    
    func createFpTags() -> Metadata {
        var meta = Metadata();
        meta.setTag(self.sourceType.rawValue, forKey: "fpjsSource")
        meta.setTag(Date().timeIntervalSince1970 * 1000, forKey: "fpjsTimestamp")
        
        return meta
    }
    
}
