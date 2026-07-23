//
//  SimpleCollectorPayloadTests.swift
//  RiskTests
//  Tests
//
//  Unit tests for the pure `simple` collector payload assembly.
//

import Foundation
import XCTest
@testable import RiskSDK

class SimpleCollectorPayloadTests: XCTestCase {

    private let device: [String: Any] = [
        "manufacturerName": "Google",
        "modelName": "Pixel 7",
        "totalRam": "8000000000"
    ]

    private func buildDevice(dropFieldPaths: [String] = []) throws -> [String: Any] {
        let json = SimpleCollectorPayload.build(
            deviceId: "device-id-123",
            requestId: "req-abc",
            device: device,
            dropFieldPaths: dropFieldPaths
        )
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        return object ?? [:]
    }

    func testBuildNestsDeviceDataUnderDeviceWithRequestIdAtRoot() throws {
        let payload = try buildDevice()

        XCTAssertEqual(payload["requestId"] as? String, "req-abc")
        XCTAssertTrue(payload["device"] is [String: Any])
    }

    func testBuildIncludesDeviceIdAsVisitorId() throws {
        let payload = try buildDevice()
        let device = payload["device"] as? [String: Any]

        XCTAssertEqual(device?["visitor_id"] as? String, "device-id-123")
    }

    func testBuildKeepsProvidedDeviceFields() throws {
        let payload = try buildDevice()
        let device = payload["device"] as? [String: Any]

        XCTAssertEqual(device?["manufacturerName"] as? String, "Google")
        XCTAssertEqual(device?["modelName"] as? String, "Pixel 7")
        XCTAssertEqual(device?["totalRam"] as? String, "8000000000")
    }

    func testBuildDropsTopLevelFieldNamedInDropFieldPaths() throws {
        let payload = try buildDevice(dropFieldPaths: ["modelName"])
        let device = payload["device"] as? [String: Any]

        XCTAssertNil(device?["modelName"])
        // Other fields are untouched.
        XCTAssertEqual(device?["manufacturerName"] as? String, "Google")
        XCTAssertEqual(device?["visitor_id"] as? String, "device-id-123")
    }

    func testBuildIgnoresDropPathsThatDoNotResolve() throws {
        let payload = try buildDevice(dropFieldPaths: ["doesNotExist", "manufacturerName.nested.path"])
        let device = payload["device"] as? [String: Any]

        XCTAssertEqual(device?["manufacturerName"] as? String, "Google")
    }

    func testDropPathRemovesDeeplyNestedField() {
        var root: [String: Any] = [
            "canvas": [
                "value": [
                    "geometry": "g",
                    "text": "t"
                ]
            ]
        ]

        SimpleCollectorPayload.dropPath(&root, path: "canvas.value.geometry")

        let value = (root["canvas"] as? [String: Any])?["value"] as? [String: Any]
        XCTAssertNil(value?["geometry"])
        XCTAssertEqual(value?["text"] as? String, "t")
    }

    func testDropPathIsNoOpWhenIntermediateSegmentNotObject() {
        var root: [String: Any] = ["manufacturerName": "Google"]

        SimpleCollectorPayload.dropPath(&root, path: "manufacturerName.value")

        XCTAssertEqual(root["manufacturerName"] as? String, "Google")
    }

    func testDeviceKeyCamelCasesLabels() {
        XCTAssertEqual(SimpleCollectorPayload.deviceKey(from: "Device model"), "deviceModel")
        XCTAssertEqual(SimpleCollectorPayload.deviceKey(from: "Screen resolution"), "screenResolution")
        // Single-token labels keep existing camelCase, only lowercasing the first character.
        XCTAssertEqual(SimpleCollectorPayload.deviceKey(from: "manufacturerName"), "manufacturerName")
    }
}
