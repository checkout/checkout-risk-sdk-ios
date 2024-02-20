//
//  RiskError.swift
//  
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public enum RiskError: LocalizedError, Equatable {
  case integrationDisabled
  case couldNotPublishRiskData
  case couldNotRetrieveConfiguration
  case couldNotPersisRiskData
  case fingerprintServiceIsNotConfigured

  public var errorDescription: String? {
    switch self {
    case .integrationDisabled:
      return "Integration disabled"

    case .couldNotPublishRiskData:
      return "Error publishing risk data"

    case .couldNotRetrieveConfiguration:
      return "Error retrieving configuration"

    case .couldNotPersisRiskData:
      return "Error persisting risk data"

    case .fingerprintServiceIsNotConfigured:
      return "Fingerprint service is not configured. Please call configure() method first."
    }
  }
}
