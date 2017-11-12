import XCTest
@testable import VueFlux

final class DispatcherTests: XCTestCase {
    func testSubscribeAndDispatch() {
        let dispatcher = Dispatcher<TestState>()
        
        var value = 0
        
        _ = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        XCTAssertEqual(value, 0)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 2)
    }
    
    func testUnsubscribeAndDispatch() {
        let dispatcher = Dispatcher<TestState>()
        
        var value = 0
        
        let subscription = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        subscription.unsubscribe()
        
        XCTAssertEqual(value, 0)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 0)
        
        _ = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
    }
}
