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

enum RiskIntegrationType: String {
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
    let integrationType: RiskIntegrationType
    
    init(config: RiskConfig) {
        self.merchantPublicKey = config.publicKey
        self.integrationType = config.framesMode ? RiskIntegrationType.RiskIosInFramesIos : RiskIntegrationType.RiskIosStandalone
        
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
