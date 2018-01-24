import XCTest
@testable import VueFluxReactive

final class DisposableScopeTests: XCTestCase {
    func testdispose() {
        var value = 0
        let disposableScope = DisposableScope()
        
        let disposable1 = AnyDisposable {
            value += 1
        }
        
        let disposable2 = AnyDisposable {
            value += 10
        }
        
        disposableScope += disposable1
        disposableScope += disposable2
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(disposable1.isDisposed, false)
        XCTAssertEqual(disposable2.isDisposed, false)
        XCTAssertEqual(disposableScope.isDisposed, false)
        
        disposableScope.dispose()
        
        XCTAssertEqual(value, 11)
        XCTAssertEqual(disposable1.isDisposed, true)
        XCTAssertEqual(disposable2.isDisposed, true)
        XCTAssertEqual(disposableScope.isDisposed, true)
    }
    
    func testDisposeOnDeinit() {
        var value = 0
        var disposableScope: DisposableScope? = .init()
        
        let disposable1 = AnyDisposable {
            value += 1
        }
        
        let disposable2 = AnyDisposable {
            value += 10
        }
        
        disposableScope! += disposable1
        disposableScope! += disposable2
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(disposable1.isDisposed, false)
        XCTAssertEqual(disposable2.isDisposed, false)
        XCTAssertEqual(disposableScope?.isDisposed, false)
        
        disposableScope = nil
        
        XCTAssertEqual(value, 11)
        XCTAssertEqual(disposable1.isDisposed, true)
        XCTAssertEqual(disposable2.isDisposed, true)
    }
}
