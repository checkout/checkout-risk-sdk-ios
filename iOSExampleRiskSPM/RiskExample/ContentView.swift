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
	@State private var deviceSessionId: String?
	@State private var error: String?
	@State private var enabled: Bool = false
	@State private var checked: Bool = false
	@State private var loading: Bool = false

	@State private var riskSDK: Risk!

	var body: some View {
		Text("Risk iOS Example - SPM").padding(.bottom).frame(maxWidth: .infinity, alignment: .center).font(.title)

		VStack(alignment: .leading) {

			Text("Card no: 0000 1234 6549 15151")
			Text("Card exp: 12/26")
			Text("Card CVV: 500").padding(.bottom)

		}
		.padding().background(Color.gray.opacity(0.1))

		Button("Pay $1400") {
			guard let publicKey = ProcessInfo.processInfo.environment["SAMPLE_MERCHANT_PUBLIC_KEY"] else {
				error = "Environment variable (SAMPLE_MERCHANT_PUBLIC_KEY) not set"
				return
			}

			let yourConfig = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa)
			self.riskSDK = Risk.init(config: yourConfig)

			checked = true
			loading = true
			error = nil

			self.riskSDK.configure { errorResponse in
				loading = false

				if let errorResponse = errorResponse {
					error = errorResponse.localizedDescription
					enabled = false
					return
				}

				enabled = true

				self.riskSDK.publishData { result in

					switch result {
					case .success(let response):
						deviceSessionId = response.deviceSessionId
					case .failure(let errorResponse):
						deviceSessionId = nil
						error = errorResponse.localizedDescription
					}
				}
			}
		}.padding().background(Color.blue.opacity(0.9)).cornerRadius(8).frame(maxWidth: .infinity, alignment: .center).foregroundColor(.white).padding(.top)

		Text(error ?? (!checked ? .init() : loading ? "Loading..." : enabled && deviceSessionId != nil ? "Device session id: \(deviceSessionId!)" : "Integration disabled") ).padding(.top).multilineTextAlignment(.center)
	}
}

#Preview {
	ContentView()
}
