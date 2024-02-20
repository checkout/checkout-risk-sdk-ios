//
//  RiskSDKInternalConfig.swift
//
//
//  Created by Precious Ossai on 20/02/2024.
//

import Foundation

struct RiskSDKInternalConfig {
    let merchantPublicKey: String
    let deviceDataEndpoint: String
    let fingerprintEndpoint: String
    let integrationType: RiskIntegrationType
    let sourceType: SourceType
    let framesMode: Bool
    let environment: RiskEnvironment

    init(config: RiskConfig) {
        merchantPublicKey = config.publicKey
        environment = config.environment
        framesMode = config.framesMode
        integrationType = framesMode ? .inFrames : .standalone
        sourceType = framesMode ? .cardToken : .riskSDK

        switch environment {
        case .qa:
            deviceDataEndpoint = "https://prism-qa.ckotech.co/collect"
            fingerprintEndpoint = "https://fpjs.cko-qa.ckotech.co"
        case .sandbox:
            deviceDataEndpoint = "https://risk.sandbox.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.sandbox.checkout.com"
        case .prod:
            deviceDataEndpoint = "https://risk.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.checkout.com"
        }
    }

}
