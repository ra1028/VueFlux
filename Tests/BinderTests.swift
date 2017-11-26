import XCTest
@testable import VueFluxReactive

final class BinderTests: XCTestCase {
    private final class Object {
        var value = 0
    }
    
    func testBind() {
        let object = Object()
        
        let binder = Binder(target: object) { $0.value = $1 }
        
        binder.bind(value: 1)
        
        XCTAssertEqual(object.value, 1)
    }
    
    func testBindWithExercutor() {
        let object = Object()
        
        let expectation = self.expectation(description: "bind on global queue")
        
        let binder = Binder<Int>(executor: .queue(.globalDefault()), target: object) {
            $0.value = $1
            expectation.fulfill()
        }
        
        binder.bind(value: 1)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(object.value, 1)
        }
    }
    
    func testBindWithKeyPath() {
        let object = Object()
        
        let binder = Binder(target: object, \.value)
        
        binder.bind(value: 1)
        
        XCTAssertEqual(object.value, 1)
    }
}
