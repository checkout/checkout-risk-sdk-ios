//
//  RiskSdkConfig.swift
//  Risk
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
    case riskIosStandalone = "RiskIosStandalone"
    case riskIosInFramesIos = "RiskIosInFramesIos"
}

enum RiskEvent {
    case publishDisabled
    case published
    case publishBlocked
    case publishFailure
    case collected
}


public struct RiskConfig {
    public let publicKey: String // merchant public key
    public let environment: RiskEnvironment // qa | sandbox | prod
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
    let integrationType: RiskIntegrationType
    
    init(config: RiskConfig) {
        self.merchantPublicKey = config.publicKey
        self.integrationType = config.framesMode ? RiskIntegrationType.riskIosInFramesIos : RiskIntegrationType.riskIosStandalone
        
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
