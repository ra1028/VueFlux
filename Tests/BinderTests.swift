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
    
    func testBindWithKeyPath() {
        let object = Object()
        
        let binder = Binder(target: object, \.value)
        
        binder.bind(value: 1)
        
        XCTAssertEqual(object.value, 1)
    }
}
