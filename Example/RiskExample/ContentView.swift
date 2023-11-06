//
//  ContentView.swift
//  RiskExample
//
//  Created by Precious Ossai on 11/10/2023.
//

import SwiftUI
import Risk

import Foundation

struct ContentView: View {
    
    var body: some View {
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("Risk iOS")
            
            Button("Initialise Risk") {
                let yourConfig = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
                
                Risk.createInstance(config: yourConfig) { 
                    riskInstance in
                    riskInstance?.publishDeviceData()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
