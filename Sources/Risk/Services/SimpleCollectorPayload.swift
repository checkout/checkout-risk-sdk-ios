//
//  SimpleCollectorPayload.swift
//  Risk
//  Sources
//
//  Pure (device-free) assembly of the `simple` collector payload.
//

import Foundation

/// Pure assembly of the `simple` collector payload, kept separate from `SimpleService`
/// so the serialisation and drop-field logic can be unit tested without a device. The
/// service layer owns the device-only concerns (running the fingerprinter, flattening the
/// signal tree and base64-encoding the result).
enum SimpleCollectorPayload {

    /// Builds the JSON payload (pre-base64) for the collector:
    /// `{ "requestId": <id>, "device": { "visitor_id": <id>, <field>: <value>, … } }`,
    /// with every `dropFieldPaths` entry removed from the `device` object.
    ///
    /// - Parameters:
    ///   - deviceId: The on-device computed id, sent as `device.visitor_id`.
    ///   - requestId: The client-generated request id, echoed at the payload root.
    ///   - device: The flattened device signals gathered from fingerprintjs-ios.
    ///   - dropFieldPaths: Dot-notation paths into `device` to remove before encoding.
    ///
    /// - Returns: The JSON payload, or nil when it could not be serialised. Nil must be treated
    ///   as a collection failure by the caller: `flatten` types signal values as `Any`, so a value
    ///   that `JSONSerialization` rejects (a `Date`, an `NSNumber` edge case, a non-UTF8 string)
    ///   is possible. Returning a placeholder such as `"{}"` here would be a *valid* payload and
    ///   would publish a device session carrying no device data as a success.
    static func build(deviceId: String, requestId: String, device: [String: Any], dropFieldPaths: [String]) -> String? {
        var deviceObject = device
        deviceObject["visitor_id"] = deviceId

        for path in dropFieldPaths {
            dropPath(&deviceObject, path: path)
        }

        let payload: [String: Any] = [
            "requestId": requestId,
            "device": deviceObject
        ]

        // `isValidJSONObject` first, and not merely `try?`: for an unsupported value
        // `JSONSerialization.data(withJSONObject:)` raises an Objective-C
        // `NSInvalidArgumentException` rather than throwing a Swift error, which no `do`/`catch`
        // here can intercept — it would terminate the host app. The check is the only way to
        // turn that into a recoverable collector failure.
        guard JSONSerialization.isValidJSONObject(payload) else { return nil }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            return String(data: data, encoding: .utf8)
        } catch {
            // The single point where a serialisation failure is observable; once a logger is
            // injected into `SimpleService` this is where the error should be reported from.
            return nil
        }
    }

    /// Derives a stable, readable camelCase key from a signal label, e.g.
    /// "Device model" -> "deviceModel", "OS version" -> "oSVersion". Single-word labels
    /// keep any existing camelCase and only have their first character lowercased.
    static func deviceKey(from label: String) -> String {
        let words = label.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard let first = words.first else { return "unknown" }

        let head = first.prefix(1).lowercased() + first.dropFirst()
        let tail = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        return head + tail
    }

    /// Removes the field at `path` (dot-notation) from `root`, walking nested objects. A path
    /// that does not fully resolve to an existing field is a no-op, so stale or platform-specific
    /// paths returned by the backend are simply ignored.
    static func dropPath(_ root: inout [String: Any], path: String) {
        let segments = path.split(separator: ".").map(String.init)
        guard !segments.isEmpty else { return }

        if segments.count == 1 {
            root.removeValue(forKey: segments[0])
            return
        }

        let key = segments[0]
        guard var child = root[key] as? [String: Any] else { return }
        dropPath(&child, path: segments.dropFirst().joined(separator: "."))
        root[key] = child
    }
}
