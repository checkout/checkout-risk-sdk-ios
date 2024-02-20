import Foundation
import CheckoutEventLoggerKit

struct MockLoggerService: LoggerServiceProtocol {
    private var loggedEvents: [RiskEvent] = []
    private var metadata: [String: String] = [:]

    init(internalConfig: RiskSDKInternalConfig) {}

    func log(riskEvent: RiskEvent, deviceSessionId: String?, requestId: String?, error: RiskLogError?) {}
}
