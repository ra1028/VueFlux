import XCTest
@testable import VueFluxReactive

final class SubscriptionScopeTests: XCTestCase {
    func testUnsubscribe() {
        var value = 0
        let subscriptionScope = SubscriptionScope()
        
        let subscription1 = AnySubscription {
            value += 1
        }
        
        let subscription2 = AnySubscription {
            value += 10
        }
        
        subscriptionScope += subscription1
        subscriptionScope += subscription2
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(subscription1.isUnsubscribed, false)
        XCTAssertEqual(subscription2.isUnsubscribed, false)
        XCTAssertEqual(subscriptionScope.isUnsubscribed, false)
        
        subscriptionScope.unsubscribe()
        
        XCTAssertEqual(value, 11)
        XCTAssertEqual(subscription1.isUnsubscribed, true)
        XCTAssertEqual(subscription2.isUnsubscribed, true)
        XCTAssertEqual(subscriptionScope.isUnsubscribed, true)
    }
    
    func testUnsubscribeOnDeinit() {
        var value = 0
        var subscriptionScope: SubscriptionScope? = .init()
        
        let subscription1 = AnySubscription {
            value += 1
        }
        
        let subscription2 = AnySubscription {
            value += 10
        }
        
        subscriptionScope! += subscription1
        subscriptionScope! += subscription2
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(subscription1.isUnsubscribed, false)
        XCTAssertEqual(subscription2.isUnsubscribed, false)
        XCTAssertEqual(subscriptionScope?.isUnsubscribed, false)
        
        subscriptionScope = nil
        
        XCTAssertEqual(value, 11)
        XCTAssertEqual(subscription1.isUnsubscribed, true)
        XCTAssertEqual(subscription2.isUnsubscribed, true)
    }
}
