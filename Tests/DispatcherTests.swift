import XCTest
@testable import VueFlux

final class DispatcherTests: XCTestCase {
    func testSubscribeAndDispatch() {
        let dispatcher = Dispatcher<TestState>()
        
        var value = 0
        
        _ = dispatcher.subscribe(on: .immediate) {
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
        
        let key = dispatcher.subscribe(on: .immediate) {
            value += 1
        }
        
        dispatcher.unsubscribe(for: key)
        
        XCTAssertEqual(value, 0)
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 0)
        
        _ = dispatcher.subscribe(on: .immediate) {
            value += 1
        }
        
        dispatcher.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
    }
}
