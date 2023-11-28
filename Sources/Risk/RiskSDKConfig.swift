//
//  RiskSdkConfig.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import FingerprintPro

public enum RiskEnvironment: String {
    case qa
    case sandbox
    case prod
}

enum RiskIntegrationType: String, Codable {
    case standalone = "RiskIosStandalone"
    case inFrames = "RiskIosInFramesIos"
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
