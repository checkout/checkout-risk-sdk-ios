//
//  DeviceCollector.swift
//
//
//  Device collectors supported by the SDK.
//

import Foundation

/// Device collectors supported by the SDK. A collector is enabled when its
/// `collectorName` is present in the `data_collectors` list returned by the
/// `configurations` endpoint. The backend derives the `device_collector_provider`
/// recorded on prism_events from this name.
enum DeviceCollector: String {
    /// FingerprintPRO — device id resolved server-side; travels via the root `fp_request_id`.
    case fingerprint

    /// Open-source fingerprintjs-ios — device id computed locally, no backend call.
    case simple

    var collectorName: String { rawValue }
}
