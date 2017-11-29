import XCTest
import VueFlux
@testable import VueFluxReactive

final class ImmutableTests: XCTestCase {
    func testSubscribe() {
        let mutable = Mutable(value: 0)
        
        let immutable = mutable.immutable
        
        var value: Int? = nil
        
        immutable.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(immutable.value, 0)
        XCTAssertEqual(value, 0)
        
        mutable.value = 1
        
        XCTAssertEqual(immutable.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testSubscribeWithExercutor() {
        let mutable = Mutable(value: 0)
        
        let immutable = mutable.immutable
        
        var value: Int? = nil
        
        let expectation = self.expectation(description: "subscribe to mutable on global queue")
        
        immutable.subscribe(executor: .queue(.globalDefault())) { int in
            XCTAssertFalse(Thread.isMainThread)
            value = int
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(immutable.value, 0)
            XCTAssertEqual(value, 0)
        }
    }
    
    func testUnsubscribe() {
        let mutable = Mutable(value: 0)
        
        let immutable = mutable.immutable
        
        var value: Int? = nil
        
        let subscription = immutable.subscribe { int in
            value = int
        }
        
        XCTAssertEqual(immutable.value, 0)
        XCTAssertEqual(value, 0)
        
        mutable.value = 1
        
        XCTAssertEqual(immutable.value, 1)
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        mutable.value = 2
        
        XCTAssertEqual(immutable.value, 2)
        XCTAssertEqual(value, 1)
        
        immutable.subscribe { int in
            value = int
        }
        
        XCTAssertEqual(immutable.value, 2)
        XCTAssertEqual(value, 2)
    }
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let mutable = Mutable(value: 0)
        
        let immutable = mutable.immutable
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        immutable.bind(to: binder)
        
        mutable.value = 1
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        mutable.value = 2
        
        XCTAssertEqual(value, 1)
    }
    
    func testMapValues() {
        let mutable = Mutable(value: 0)
        
        let immutable = mutable.immutable
        
        var value: String?
        
        let subscription = immutable.map(String.init(_:)).subscribe { string in
            value = string
        }
        
        XCTAssertEqual(value, "0")
        
        mutable.value = 1
        
        XCTAssertEqual(value, "1")
        
        subscription.unsubscribe()
        
        mutable.value = 2
        
        XCTAssertEqual(value, "1")
    }
}
