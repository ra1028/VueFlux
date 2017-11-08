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
        
        let key = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        dispatcher.unsubscribe(for: key)
        
        XCTAssertEqual(value, 0)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 0)
        
        _ = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
    }
    
    func testUnsubscribeWithInvalidKey() {
        let dispatcher = Dispatcher<TestState>()
        
        var value = 0
        
        _ = dispatcher.subscribe(executor: .immediate) {
            value += 1
        }
        
        let invalidKey = Dispatcher<TestState>.Key.first.next
        
        dispatcher.unsubscribe(for: invalidKey)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
    }
}
