import XCTest
@testable import VueFluxReactive

final class SubscriptionTests: XCTestCase {
    func testAnySubscription() {
        var value = 0
        
        let subscription = AnySubscription {
            value += 1
        }
        
        XCTAssertEqual(subscription.isUnsubscribed, false)
        
        subscription.unsubscribe()
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(subscription.isUnsubscribed, true)
        
        subscription.unsubscribe()
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(subscription.isUnsubscribed, true)
    }
}
