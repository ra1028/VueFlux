import XCTest
@testable import VueFluxReactive

final class DisposableScopeTests: XCTestCase {
    func testDispose() {
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
    
    func testAddDisposableToDisposed() {
        var value = 0
        
        let disposable = AnyDisposable {
            value = 1
        }
        
        let disposableScope = DisposableScope()
        
        XCTAssertEqual(value, 0)
        XCTAssertEqual(disposable.isDisposed, false)
        XCTAssertEqual(disposableScope.isDisposed, false)
        
        disposableScope.dispose()
        disposableScope += disposable
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(disposable.isDisposed, true)
        XCTAssertEqual(disposableScope.isDisposed, true)
    }
    
    func testAddDiposableAlreadyDisposed() {
        var disposable: DisposableScope? = .init()
        weak var disposableRef = disposable
        
        disposable?.dispose()
        
        let disposableScope = DisposableScope()
        disposableScope += disposable!
        
        disposable = nil
        
        XCTAssertNil(disposableRef)
    }
}
