//
//  RiskIos.swift
//  RiskIos
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//
// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class Risk {
    private static var sharedInstance: Risk?
    
    public init() {
        print("RiskIos Initialized")
    }
    
    public static func createInstance(config: RiskIosConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSdkInternalConfig(config: config)
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
