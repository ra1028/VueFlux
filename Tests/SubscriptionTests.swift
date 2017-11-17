import XCTest
@testable import VueFlux

final class SubscriptionTests: XCTestCase {
    func testUnsbscribe() {
        var value = 0
        
        let subscription = Subscription {
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
