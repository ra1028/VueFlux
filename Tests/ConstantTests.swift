import XCTest
import VueFlux
@testable import VueFluxReactive

final class ConstantTests: XCTestCase {
    func testObserve() {
        let variable = Variable(0)
        let constant = variable.constant
        
        var value: Int? = nil
        
        constant.signal.observe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(constant.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1
        
        XCTAssertEqual(constant.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testdispose() {
        let variable = Variable(0)
        let constant = variable.constant
        
        var value: Int? = nil
        
        let disposable = constant.signal.observe { int in
            value = int
        }
        
        XCTAssertEqual(constant.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1
        
        XCTAssertEqual(constant.value, 1)
        XCTAssertEqual(value, 1)
        
        disposable.dispose()
        
        variable.value = 2
        
        XCTAssertEqual(constant.value, 2)
        XCTAssertEqual(value, 1)
        
        constant.signal.observe { int in
            value = int
        }
        
        XCTAssertEqual(constant.value, 2)
        XCTAssertEqual(value, 2)
    }
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let variable = Variable(0)
        let constant = variable.constant
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        constant.signal.bind(to: binder)
        
        variable.value = 1
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        variable.value = 2
        
        XCTAssertEqual(value, 1)
        
        let disposable = constant.signal.bind(to: binder)
        
        XCTAssertTrue(disposable.isDisposed)
    }
    
    func testMapValues() {
        let variable = Variable(0)
        let constant = variable.constant
        
        var value: String?
        
        let disposable = constant.signal
            .map(String.init(_:))
            .observe { string in
                value = string
        }
        
        XCTAssertEqual(value, "0")
        
        variable.value = 1
        
        XCTAssertEqual(value, "1")
        
        disposable.dispose()
        
        variable.value = 2
        
        XCTAssertEqual(value, "1")
    }
    
    func testObserveOn() {
        let variable = Variable(0)
        let constant = Constant(variable: variable)
        let signal = constant.signal
        
        var value: Int?
        
        let expectation = self.expectation(description: "testObserveOn")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .observe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
