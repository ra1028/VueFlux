import XCTest
import VueFlux
@testable import VueFluxReactive

final class MutableTests: XCTestCase {
    func testSubscribe() {
        let mutable = Mutable(value: 0)
        
        var value: Int? = nil
        
        mutable.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(mutable.value, 0)
        XCTAssertEqual(value, 0)
        
        mutable.value = 1

        XCTAssertEqual(mutable.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testSubscribeWithExercutor() {
        let mutable = Mutable(value: 0)
        
        var value: Int? = nil
        
        let expectation = self.expectation(description: "subscribe to mutable on global queue")
        
        mutable.subscribe(executor: .queue(.globalQueue())) { int in
            XCTAssertFalse(Thread.isMainThread)
            value = int
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(mutable.value, 0)
            XCTAssertEqual(value, 0)
        }
    }
    
    func testUnsubscribe() {
        let mutable = Mutable(value: 0)
        
        var value: Int? = nil
        
        let subscription = mutable.subscribe { int in
            value = int
        }

        XCTAssertEqual(mutable.value, 0)
        XCTAssertEqual(value, 0)
        
        mutable.value = 1
        
        XCTAssertEqual(mutable.value, 1)
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        mutable.value = 2
        
        XCTAssertEqual(mutable.value, 2)
        XCTAssertEqual(value, 1)
        
        mutable.subscribe { int in
            value = int
        }
        
        XCTAssertEqual(mutable.value, 2)
        XCTAssertEqual(value, 2)
    }
}
