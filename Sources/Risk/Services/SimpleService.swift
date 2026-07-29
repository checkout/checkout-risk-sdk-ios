//
//  SimpleService.swift
//  Risk
//  Sources
//
//  Wraps the open-source fingerprintjs-ios library — the `simple` collector.
//

import FingerprintJS
import Foundation

struct SimplePublishData {
    let deviceId: String
    let requestId: String
    let sealedResult: String
}

protocol SimpleServiceProtocol {
    func publishData(completion: @escaping (Result<SimplePublishData, RiskError.Publish>) -> Void)
}

/// Service wrapping the open-source
/// [fingerprintjs-ios](https://github.com/fingerprintjs/fingerprintjs-ios) library — the
/// `simple` collector.
///
/// Unlike the PRO collector, this computes a device id entirely on-device with no backend
/// call, so its ability to dedupe similar devices is reduced. Its purpose here is to provide
/// a second, free device id alongside PRO for downstream comparison.
final class SimpleService: SimpleServiceProtocol {
    private let fingerprinter: Fingerprinter
    private let dropFieldPaths: [String]
    private let timeoutMs: Int?

    /// - Parameters:
    ///   - dropFieldPaths: Dot-notation paths into the `device` data that the `configurations`
    ///     endpoint asked to drop before encoding (e.g. "canvas.value.geometry"). Paths that do
    ///     not resolve against the collected data are ignored.
    ///   - timeoutMs: Collection timeout budget in milliseconds, as supplied by the
    ///     `configurations` endpoint. When collection exceeds this budget the collector fails
    ///     so the remaining collectors can still publish. Nil (or non-positive) leaves collection
    ///     unbounded, in which case only the global publish timer applies.
    ///   - fingerprinter: The fingerprintjs-ios fingerprinter (injectable for testing).
    init(
        dropFieldPaths: [String] = [],
        timeoutMs: Int? = nil,
        fingerprinter: Fingerprinter = FingerprinterFactory.getInstance(Configuration(version: .latest, stabilityLevel: .optimal))
    ) {
        self.dropFieldPaths = dropFieldPaths
        self.timeoutMs = timeoutMs
        self.fingerprinter = fingerprinter
    }

    /// Collects the open-source device data asynchronously.
    ///
    /// The raw device signals (manufacturer, model, OS, screen, locale, …) are gathered
    /// alongside the computed device id and assembled into a `device` object, mirroring the
    /// `simple` collector in the JS SDK. That payload is JSON-serialised and base64-encoded
    /// into `SimplePublishData.sealedResult` so it can travel in the `sealed_result` field of
    /// the `fingerprint/v2` collectors payload.
    ///
    /// The generated `requestId` matches the `requestId` embedded in the payload; the caller
    /// uses it as the root `fp_request_id` when the PRO collector is absent.
    func publishData(completion: @escaping (Result<SimplePublishData, RiskError.Publish>) -> Void) {
        // Signal collection and the timeout race each other; whichever finishes first wins and
        // the completion is invoked exactly once. `hasCompleted` is guarded by `lock` because the
        // fingerprintjs callbacks and the timeout fire on different queues.
        let lock = NSLock()
        var hasCompleted = false
        func finish(_ result: Result<SimplePublishData, RiskError.Publish>) {
            lock.lock()
            defer { lock.unlock() }
            guard !hasCompleted else { return }
            hasCompleted = true
            completion(result)
        }

        // Bound collection by the backend-provided budget. A non-positive or absent budget leaves
        // collection unbounded (only the global publish timer in `Risk.publishData` then applies).
        if let timeoutMs, timeoutMs > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                finish(.failure(.couldNotPublishRiskData))
            }
        }

        fingerprinter.getDeviceId { [weak self] deviceId in
            guard let self = self else { return }

            self.fingerprinter.getFingerprintTree { tree in
                let device = SimpleService.flatten(tree: tree)
                let requestId = UUID().uuidString
                // The vendor identifier can be nil (e.g. denied); fall back to the request id
                // so the payload always carries a stable visitor id.
                let visitorId = deviceId ?? requestId

                let payloadJson = SimpleCollectorPayload.build(
                    deviceId: visitorId,
                    requestId: requestId,
                    device: device,
                    dropFieldPaths: self.dropFieldPaths
                )

                guard let sealedResult = payloadJson.data(using: .utf8)?.base64EncodedString() else {
                    return finish(.failure(.couldNotPublishRiskData))
                }

                finish(.success(SimplePublishData(
                    deviceId: visitorId,
                    requestId: requestId,
                    sealedResult: sealedResult
                )))
            }
        }
    }

    /// Flattens the fingerprintjs-ios `FingerprintTree` into a nested `device` object:
    /// category nodes become nested objects, leaf info nodes become string values, both keyed
    /// by the camelCased signal label. Dot-notation `dropFieldPaths` map naturally onto the
    /// resulting nesting.
    static func flatten(tree: FingerprintTree) -> [String: Any] {
        flattenChildren(tree)
    }

    private static func flattenChildren(_ node: FingerprintTree) -> [String: Any] {
        var result: [String: Any] = [:]
        guard let children = node.children else { return result }

        for child in children {
            let key = SimpleCollectorPayload.deviceKey(from: child.info.label)
            switch child.info.value {
            case .info(let value):
                result[key] = value
            case .category:
                result[key] = flattenChildren(child)
            }
        }
        return result
    }
}
