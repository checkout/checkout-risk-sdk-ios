//
//  RiskSdkConfig.swift
//  RiskIos
//  Sources
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation

public enum RiskEnvironment {
    case qa
    case sandbox
    case production
}

internal enum RiskIntegrationType: String {
    case RiskJsStandalone = "RiskJsStandalone" // TODO: - Update this value to use RiskIosStandalone
    case RiskIosFrames = "RiskJsInFramesJs" // TODO: - Update this value to use RiskIosInFramesIos
}

enum RiskEvent {
    case riskDataPublishDisabled
    case riskDataPublished
    case riskDataPublishBlocked
    case riskDataPublishFailure
    case riskDataCollected
}


public struct RiskIosConfig {
    public let publicKey: String // merchant public key
    public let environment: RiskEnvironment // qa | sandbox | prod
    public let framesMode: Bool
    
    public init(publicKey: String, environment: RiskEnvironment, framesMode: Bool = false) {
        self.publicKey = publicKey
        self.environment = environment
        self.framesMode = framesMode
    }
}

struct RiskSdkInternalConfig {
    let merchantPublicKey: String
    let deviceDataEndpoint: String
    let integrationType: RiskIntegrationType
    
    init(config: RiskIosConfig) {
        self.merchantPublicKey = config.publicKey
        self.integrationType = config.framesMode ? RiskIntegrationType.RiskIosFrames : RiskIntegrationType.RiskJsStandalone
        
        switch config.environment {
        case .qa:
            self.deviceDataEndpoint = "https://prism-qa.ckotech.co/collect"
        case .sandbox:
            self.deviceDataEndpoint = "https://risk.sandbox.checkout.com/collect"
        case .production:
            self.deviceDataEndpoint = "https://risk.checkout.com/collect"
        }
    }
}
