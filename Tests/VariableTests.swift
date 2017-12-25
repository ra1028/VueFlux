import XCTest
import VueFlux
@testable import VueFluxReactive

final class VariableTests: XCTestCase {
    func testSubscribe() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        variable.signal.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(variable.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1

        XCTAssertEqual(variable.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testUnsubscribe() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        let subscription = variable.signal.subscribe { int in
            value = int
        }

        XCTAssertEqual(variable.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1
        
        XCTAssertEqual(variable.value, 1)
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        variable.value = 2
        
        XCTAssertEqual(variable.value, 2)
        XCTAssertEqual(value, 1)
        
        variable.signal.subscribe { int in
            value = int
        }
        
        XCTAssertEqual(variable.value, 2)
        XCTAssertEqual(value, 2)
    }
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let variable = Variable(0)
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        variable.signal.bind(to: binder)
        
        variable.value = 1
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        variable.value = 2
        
        XCTAssertEqual(value, 1)
        
        let subscription = variable.signal.bind(to: binder)
        
        XCTAssertTrue(subscription.isUnsubscribed)
    }
    
    func testMapValues() {
        let variable = Variable(0)
        
        var value: String?
        
        let subscription = variable.signal.map(String.init(_:)).subscribe { string in
            value = string
        }
        
        XCTAssertEqual(value, "0")
        
        variable.value = 1
        
        XCTAssertEqual(value, "1")
        
        subscription.unsubscribe()
        
        variable.value = 2
        
        XCTAssertEqual(value, "1")
    }
    
    func testObserveOn() {
        let variable = Variable(0)
        let signal = variable.signal
        
        var value: Int?
        
        let expectation = self.expectation(description: "subscribe to signal on global queue")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .subscribe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
