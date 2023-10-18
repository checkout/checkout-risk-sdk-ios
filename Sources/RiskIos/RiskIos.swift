//
//  Risk.swift
//  Created by Precious Ossai on 13/10/2023.
//
// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class Risk {
    private var publicKey: String
    
    public init(publicKey: String) {
        self.publicKey = publicKey
        print("Risk package initialised with public key: \(self.publicKey)")
    }
}
