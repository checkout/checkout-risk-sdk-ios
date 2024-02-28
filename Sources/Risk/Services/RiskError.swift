//
//  RiskError.swift
//
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public enum RiskError {
    case configuration(Configuration)
    case publish(Publish)
}

public extension RiskError {
    enum Configuration: LocalizedError {
        case integrationDisabled
        case couldNotRetrieveConfiguration
        
        public var errorDescription: String? {
            switch self {
            case .integrationDisabled:
                return "Integration disabled"
                
            case .couldNotRetrieveConfiguration:
                return "Error retrieving configuration"
            }
        }
    }
    
    enum Publish: LocalizedError {
        case couldNotPublishRiskData
        case couldNotPersisRiskData
        case fingerprintServiceIsNotConfigured
        
        public var errorDescription: String? {
            switch self {
            case .couldNotPublishRiskData:
                return "Error publishing risk data"
                
            case .couldNotPersisRiskData:
                return "Error persisting risk data"
                
            case .fingerprintServiceIsNotConfigured:
                return "Fingerprint service is not configured. Please call configure() method first."
            }
        }
    }
}
