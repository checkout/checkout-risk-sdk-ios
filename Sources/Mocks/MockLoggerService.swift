import Foundation
import CheckoutEventLoggerKit

struct MockLoggerService: LoggerServiceProtocol {
    private var loggedEvents: [RiskEvent] = []
    private var metadata: [String: String] = [:]

    init(internalConfig: RiskSDKInternalConfig) {}

    func log(riskEvent: RiskEvent, deviceSessionID: String?, requestID: String?, error: RiskLogError?) {}
}
