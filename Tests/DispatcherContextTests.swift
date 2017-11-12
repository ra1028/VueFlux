import XCTest
@testable import VueFlux

final class DispatcherContextTests: XCTestCase {
    func testDispacherInstance() {
        let dispatcher1 = DispatcherContext.shared.dispatcher(for: TestState.self)
        let dispatcher2 = DispatcherContext.shared.dispatcher(for: TestState.self)
        
        XCTAssertEqual(ObjectIdentifier(dispatcher1), ObjectIdentifier(dispatcher2))
    }
}
