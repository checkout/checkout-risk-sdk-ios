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
    let framesMode: Bool

    public init(publicKey: String, environment: RiskEnvironment, framesMode: Bool = false) {
        self.publicKey = publicKey
        self.environment = environment
        self.framesMode = framesMode
    }
}
