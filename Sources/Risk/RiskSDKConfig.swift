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
