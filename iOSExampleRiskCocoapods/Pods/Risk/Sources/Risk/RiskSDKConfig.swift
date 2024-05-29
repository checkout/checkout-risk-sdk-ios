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
    case production
}

public struct RiskConfig {
    let publicKey: String
    let environment: RiskEnvironment
    let framesOptions: FramesOptions?

    public init(publicKey: String, environment: RiskEnvironment, framesOptions: FramesOptions? = nil) {
        self.publicKey = publicKey
        self.environment = environment
        self.framesOptions = framesOptions
    }
}

public struct FramesOptions {
    let version: String
    let productIdentifier: String

    public init(productIdentifier: String, version: String) {
        self.productIdentifier = productIdentifier
        self.version = version
    }
}
