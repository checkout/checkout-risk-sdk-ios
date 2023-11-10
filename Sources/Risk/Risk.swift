//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public class Risk {
    private static var sharedInstance: Risk?
    private let fingerprintService: FingerprintService
    
    private init(fingerprintService: FingerprintService) {
        self.fingerprintService = fingerprintService
    }
    
    public static func createInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig)
        
        deviceDataService.getConfiguration {
            configuration in
            
            guard configuration.fingerprintIntegration.enabled, let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey else {
                return completion(nil)
                // #warning("TODO: - Handle disabled fingerpint integraiton, e.g. dispatch and/or log event")
            }
            
            let fingerprintService = FingerprintService(fingerprintPublicKey: fingerprintPublicKey, internalConfig: internalConfig)
            
            let riskInstance = Risk(fingerprintService: fingerprintService)
            sharedInstance = riskInstance
            
            completion(riskInstance)
        }
    }
    
    public func publishData () {
        
        fingerprintService.publishData(cardToken: nil) { requestID in
            print("Published to Fingerprint with requestID: \(requestID ?? "")")
        }
    }
}
