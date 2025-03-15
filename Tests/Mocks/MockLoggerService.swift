import Foundation
import CheckoutEventLoggerKit
@testable import RiskSDK

struct MockLoggerService: LoggerServiceProtocol {
    private var loggedEvents: [RiskEvent] = []
    private var metadata: [String: String] = [:]

    init(internalConfig: RiskSDKInternalConfig) {}

    func log(riskEvent: RiskEvent, blockTime: Double?, deviceDataPersistTime: Double?, fpLoadTime: Double?, fpPublishTime: Double?, deviceSessionId: String?, requestId: String?, error: RiskLogError?) {}
}
