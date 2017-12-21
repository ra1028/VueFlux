import XCTest
import VueFlux
@testable import VueFluxReactive

final class VariableTests: XCTestCase {
    func testSubscribe() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        variable.stream.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(variable.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1

        XCTAssertEqual(variable.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testSubscribeWithExercutor() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        let expectation = self.expectation(description: "subscribe to variable on global queue")
        
        variable.stream.subscribe(executor: .queue(.globalDefault())) { int in
            XCTAssertFalse(Thread.isMainThread)
            value = int
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(variable.value, 0)
            XCTAssertEqual(value, 0)
        }
    }
    
    func testUnsubscribe() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        let subscription = variable.stream.subscribe { int in
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
        
        variable.stream.subscribe { int in
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
        
        variable.stream.bind(to: binder)
        
        variable.value = 1
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        variable.value = 2
        
        XCTAssertEqual(value, 1)
    }
    
    func testMapValues() {
        let variable = Variable(0)
        
        var value: String?
        
        let subscription = variable.stream.map(String.init(_:)).subscribe { string in
            value = string
        }
        
        XCTAssertEqual(value, "0")
        
        variable.value = 1
        
        XCTAssertEqual(value, "1")
        
        subscription.unsubscribe()
        
        variable.value = 2
        
        XCTAssertEqual(value, "1")
    }
}
