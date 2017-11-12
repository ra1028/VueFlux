import XCTest
@testable import VueFlux

final class DispatcherContextTests: XCTestCase {
    func testDispacherInstance() {
        let dispatcher1 = DispatcherContext.shared.dispatcher(for: TestState.self)
        
        var value = 0
        
        let subscription = dispatcher1.subscribe(executor: .immediate) {
            value += 1
        }
        
        let dispatcher2 = DispatcherContext.shared.dispatcher(for: TestState.self)
        
        dispatcher2.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        dispatcher2.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
    }
}
