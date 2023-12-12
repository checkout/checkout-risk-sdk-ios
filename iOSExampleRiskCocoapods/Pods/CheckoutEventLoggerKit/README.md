# checkout-3ds-sdk-ios-framework

Releases for `CheckoutEventLoggerKit`

`CheckoutEventLoggerKit` is an internal tool for securely logging impersonal usage data in SDKs.

## Requirements

- iOS 10.0+
- Xcode 11.0+
- Swift 5.0+

## Installation

### Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.9+ is required to use CheckoutEventLoggerKit

To integrate CheckoutEventLoggerKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CheckoutEventLoggerKit', :git => 'https://github.com/checkout/checkout-event-logger-ios-framework.git', :tag => '1.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

Carthage users should download `CheckoutEventLoggerKit.xcframework` and integrate with their project.

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Once you have your Swift package set up, adding CheckoutEventLoggerKit as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```
dependencies: [
    .package(url: "https://github.com/checkout/checkout-event-logger-ios-framework.git", .upToNextMajor(from: "1.0.0"))
]
```
