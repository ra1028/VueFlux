import XCTest
@testable import VueFlux

final class SubscriptionScopeTests: XCTestCase {
    func testUnsubscribeAllOnDeinit() {
        var value = 0
        var subscriptionScope: SubscriptionScope? = .init()
        
        let subscription1 = Subscription {
            value += 1
        }
        
        let subscription2 = Subscription {
            value += 10
        }
        
        subscriptionScope! += subscription1
        subscriptionScope! += subscription2
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(subscription1.isUnsubscribed, false)
        XCTAssertEqual(subscription2.isUnsubscribed, false)
        
        subscriptionScope = nil
        
        XCTAssertEqual(value, 11)
        XCTAssertEqual(subscription1.isUnsubscribed, true)
        XCTAssertEqual(subscription2.isUnsubscribed, true)
    }
}
