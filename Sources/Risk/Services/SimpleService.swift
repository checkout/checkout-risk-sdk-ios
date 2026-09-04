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
    /// Collects the open-source device data off the calling thread. `completion` is always
    /// invoked on the main queue, exactly once.
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
    /// Queue the fingerprintjs-ios collection runs on.
    ///
    /// Despite their completion-handler signatures, `Fingerprinter.getDeviceId` and
    /// `getFingerprintTree` invoke their completion synchronously on the calling thread, so the
    /// caller's thread absorbs the full cost of collection. Concurrent so overlapping
    /// `publishData` calls do not queue behind one another and eat into their timeout budgets.
    private static let collectionQueue = DispatchQueue(
        label: "com.checkout.risk.simple-collector",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Client-side fallback used when `configurations` omits `timeout_ms` or supplies a
    /// non-positive one. Matches the Android SDK's `DEFAULT_TIMEOUT_MS` so one merchant behaves
    /// identically on both platforms.
    static let defaultTimeoutMs = 1000

    private let fingerprinter: Fingerprinter
    private let dropFieldPaths: [String]
    private let effectiveTimeoutMs: Int

    /// - Parameters:
    ///   - dropFieldPaths: Dot-notation paths into the `device` data that the `configurations`
    ///     endpoint asked to drop before encoding (e.g. "canvas.value.geometry"). Paths that do
    ///     not resolve against the collected data are ignored.
    ///   - timeoutMs: Collection timeout budget in milliseconds, as supplied by the
    ///     `configurations` endpoint. When collection exceeds this budget the collector fails
    ///     so the remaining collectors can still publish. A nil or non-positive value means
    ///     "not configured" and falls back to `defaultTimeoutMs`; as on Android there is
    ///     deliberately no way to express "no limit", because this runs on the payment path.
    ///   - fingerprinter: The fingerprintjs-ios fingerprinter (injectable for testing).
    init(
        dropFieldPaths: [String] = [],
        timeoutMs: Int? = SimpleService.defaultTimeoutMs,
        fingerprinter: Fingerprinter = FingerprinterFactory.getInstance(Configuration(version: .latest, stabilityLevel: .optimal))
    ) {
        self.dropFieldPaths = dropFieldPaths
        self.effectiveTimeoutMs = timeoutMs.flatMap { $0 > 0 ? $0 : nil } ?? SimpleService.defaultTimeoutMs
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
    ///
    /// Collection runs on `collectionQueue` rather than the caller's thread, and `completion` is
    /// always delivered on the main queue exactly once, whichever of collection or the timeout
    /// wins the race.
    func publishData(completion: @escaping (Result<SimplePublishData, RiskError.Publish>) -> Void) {
        // Signal collection and the timeout race each other; whichever finishes first wins, its
        // result is the one reported and the completion is invoked exactly once. The loser is not
        // cancelled — collection has no cancellation to offer — its result is discarded.
        // `hasCompleted` is guarded by `lock` because the
        // collection queue and the timeout fire independently. `completion` is dispatched after
        // unlocking so the caller never runs while the lock is held.
        let lock = NSLock()
        var hasCompleted = false
        func finish(_ result: Result<SimplePublishData, RiskError.Publish>) {
            lock.lock()
            let wasCompleted = hasCompleted
            hasCompleted = true
            lock.unlock()

            guard !wasCompleted else { return }
            DispatchQueue.main.async { completion(result) }
        }

        // Bound collection by the backend-provided budget, falling back to `defaultTimeoutMs`.
        // The library exposes no cancellation, so the synchronous fingerprintjs work is *not*
        // interrupted when the budget elapses — its result is simply discarded. What the deadline
        // buys is releasing the caller (and the `DispatchGroup` in `Risk.publishData`) so the
        // remaining collectors can publish while this one finishes off-thread.
        SimpleService.collectionQueue.asyncAfter(deadline: .now() + .milliseconds(effectiveTimeoutMs)) {
            finish(.failure(.couldNotPublishRiskData))
        }

        // `getDeviceId` performs a synchronous keychain read and `getFingerprintTree` gathers every
        // signal (CoreTelephony, LocalAuthentication, sysctl, screen) and hashes the result, all
        // inline on this queue. Both are still invoked as nested callbacks so the code stays correct
        // if the library ever makes them genuinely asynchronous. `self` is captured strongly for the
        // duration: deallocating mid-collection must not strand `completion` and, with it, the
        // `DispatchGroup` in `Risk.publishData`.
        SimpleService.collectionQueue.async {
            self.fingerprinter.getDeviceId { deviceId in
                self.fingerprinter.getFingerprintTree { tree in
                    let device = SimpleService.flatten(tree: tree)
                    let requestId = UUID().uuidString
                    // The vendor identifier can be nil (e.g. denied); fall back to the request id
                    // so the payload always carries a stable visitor id.
                    let visitorId = deviceId ?? requestId

                    guard let payloadJson = SimpleCollectorPayload.build(
                              deviceId: visitorId,
                              requestId: requestId,
                              device: device,
                              dropFieldPaths: self.dropFieldPaths
                          ),
                          let sealedResult = payloadJson.data(using: .utf8)?.base64EncodedString()
                    else {
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
