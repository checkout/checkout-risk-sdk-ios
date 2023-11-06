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
    
    public init() {
        print("Risk Initialized")
    }
    
    public static func createInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig)
        
        deviceDataService.getConfiguration {
            configuration in
            
            guard configuration.fingerprintIntegration.enabled else {
                return completion(nil)
            }
            
            let riskInstance = Risk()
            sharedInstance = riskInstance
            completion(riskInstance)
        }
    }
    
    public func publishDeviceData () {
        print("Publishing")
    }
}
