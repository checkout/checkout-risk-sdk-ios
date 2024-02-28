#  Risk iOS package
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Risk.svg)](https://img.shields.io/cocoapods/v/Risk)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/checkout/checkout-risk-sdk-ios?label=spm)
[![Platform](https://img.shields.io/cocoapods/p/Risk.svg?style=flat)]()
![license](https://img.shields.io/github/license/checkout/checkout-risk-sdk-ios.svg)

The package helps collect device data for merchants with direct integration (standalone) with the package and those using [Checkout's Frames iOS package](https://github.com/checkout/frames-ios).

## Table of contents
- [Risk iOS package](#risk-ios-package)
  - [Table of contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Documentation](#documentation)
    - [Usage guide](#usage-guide)
    - [Public API](#public-api)
    - [Additional Resources](#additional-resources)
  - [Demo projects](#demo-projects)
  - [Changelog](#changelog)
  - [Contributing](#contributing)
  - [License](#license)


## Requirements
- iOS 12.0+
- Xcode 12.4+
- Swift 5.3+

## Documentation
### Usage guide
  1. Add `Risk` as a package dependency - _see [Installation guide](https://github.com/checkout/checkout-risk-sdk-ios/blob/main/.github/partial-readmes/Installation.md) on how to add our SDK in your iOS app via SPM or Cocoapods._
  2. Obtain a public API key from [Checkout Dashboard](https://dashboard.checkout.com/developers/keys).
  3. Initialise the package Risk with the public API key and environment `Risk.init(config: yourConfig)` early-on.
        <details>
        <summary>Type definitions</summary>

        ```swift
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

        public enum RiskEnvironment {
            case qa
            case sandbox
            case production
        }
        ```
        </details>
  4. Use the `configure` to complete your setup, then publish the device data within the closure with the `publishData` method. 

        <details>
        <summary>Type definitions</summary>

        ```swift
        public struct PublishRiskData {
            public let deviceSessionId: String
        }

        public enum RiskError: LocalizedError, Equatable {
            case configuration(Configuration)
            case publish(Publish)
        }

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
        ```
        </details>

See example below:
```swift
import Risk

// Example usage of package
let yourConfig = RiskConfig(publicKey: "pk_qa_xxx", environment: RiskEnvironment.qa)

self.riskSDK = Risk.init(config: yourConfig)  

self.riskSDK.configure { configurationResult in

	switch configurationResult {
	case .failure(let errorResponse):
		print(errorResponse.localizedDescription)
	case .success():
		self.riskSDK.publishData { result in
			
			switch result {
			case .success(let response):
				print(response.deviceSessionId)
			case .failure(let errorResponse):
				print(errorResponse.localizedDescription)
			}
		}
	}
	
}   
 ```

### Public API
Aside the instantiation via the `init` method, the package exposes two methods:
1. `configure` - This method completes your setup after initialisation. When the method is called, preliminary checks are made to Checkout's internal API(s) that retrieves other configurations required for collecting device data, if the checks fail or the merchant is disabled, the error is returned and logged, you can also see more information on your Xcode console while in development mode.
    <details>
    <summary>Type definitions</summary>

    ```swift
    public func configure(completion: @escaping (Result<Void, RiskError.Configuration>) -> Void) {
        ...
    }
    ```
    </details>


2. `publishData` - This is used to publish and persist the device data.

    <details>
    <summary>Type definitions</summary>

    ```swift
    public func publishData (cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError.Publish>) -> Void) {
            ...
    }
    ```
    </details>


### Additional Resources
<!-- TODO: Add website documentation link here - [Risk iOS SDK documentation](https://docs.checkout.com/risk/overview) -->
- [Frames iOS SDK documentation](https://www.checkout.com/docs/developer-resources/sdks/frames-ios-sdk)

## Demo projects
Our sample application showcases our prebuilt UIs and how our SDK works. You can run this locally once you clone the repository (whether directly via git or with suggested integration methods).

Our demo apps also test the supported integration methods (SPM, Cocoapods), so if you're having any problems there, they should offer a working example. You will find them in the root of the repository, inside respective folders:
- iOSExampleRiskCocoapods - (Cocoapods distribution)
- iOSExampleRiskSPM - (SPM distribution)
 
## Changelog
Find our CHANGELOG.md [here](https://github.com/checkout/checkout-risk-sdk-ios/blob/main/.github/CHANGELOG.md).

## Contributing
Find our guide to start contributing [here](https://github.com/checkout/checkout-risk-sdk-ios/blob/main/.github/CONTRIBUTING.md).

## License
Risk iOS is released under the MIT license. [See LICENSE](https://github.com/checkout/checkout-risk-sdk-ios/blob/main/LICENSE) for details.
