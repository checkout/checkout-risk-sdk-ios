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
    let environment: RiskEnvironment
    let framesOptions: FramesOptions?

    init(config: RiskConfig) {
        framesOptions = config.framesOptions
        let framesMode = framesOptions != nil
        merchantPublicKey = config.publicKey
        environment = config.environment
        integrationType = framesMode ? .inFrames : .standalone
        sourceType = framesMode ? .cardToken : .riskSDK

        // A missing or blank mssd falls back to the shared device data endpoint.
        let mssd = config.mssd
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }

        switch environment {
        case .qa:
            deviceDataEndpoint = mssd.map { "https://\($0).devices-egw.cko-qa.ckotech.co/collect" }
                ?? "https://prism-qa.ckotech.co/collect"
            fingerprintEndpoint = "https://fpjs.cko-qa.ckotech.co"
        case .sandbox:
            deviceDataEndpoint = mssd.map { "https://\($0).devices.api.sandbox.checkout.com/collect" }
                ?? "https://risk.sandbox.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.sandbox.checkout.com"
        case .production:
            deviceDataEndpoint = mssd.map { "https://\($0).devices.api.checkout.com/collect" }
                ?? "https://risk.checkout.com/collect"
            fingerprintEndpoint = "https://fpjs.checkout.com"
        }
    }
}
