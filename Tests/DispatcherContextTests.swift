import XCTest
@testable import VueFlux

final class DispatcherContextTests: XCTestCase {
    func testDispacherInstance() {
        var value = 0
        
        let dispatcher1 = DispatcherContext.shared.dispatcher(for: TestState.self)
        
        dispatcher1.subscribe(on: .immediate) {
            value += 1
        }
        
        let dispatcher2 = DispatcherContext.shared.dispatcher(for: TestState.self)
        
        dispatcher2.dispatch(action: ())
        
        XCTAssertEqual(value, 1)
        
        dispatcher2.subscribe(on: .immediate) {
            value += 1
        }
        
        dispatcher1.dispatch(action: ())
        
        XCTAssertEqual(value, 3)
    }
}
