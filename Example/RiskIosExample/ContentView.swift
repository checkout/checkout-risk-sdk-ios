//
//  ContentView.swift
//  RiskIosExample
//
//  Created by Precious Ossai on 11/10/2023.
//

import SwiftUI
import RiskIos

import Foundation




struct ContentView: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("Risk iOS")
            
            Button("Initialise Risk") {
                let RiskInstance = Risk.init(publicKey: "test_pk_key")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
