import XCTest
@testable import VueFluxReactive

final class DisposableTests: XCTestCase {
    func testAnyDisposable() {
        var value = 0
        
        let disposable = AnyDisposable {
            value += 1
        }
        
        XCTAssertEqual(disposable.isDisposed, false)
        
        disposable.dispose()
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(disposable.isDisposed, true)
        
        disposable.dispose()
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(disposable.isDisposed, true)
    }
}
