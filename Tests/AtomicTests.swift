import XCTest
@testable import VueFlux

final class AtomicTests: XCTestCase {
    func testSynchronized() {
        let atomic = Atomic(0)
        
        var targetValue = 1
        
        atomic.synchronized { value in
            targetValue = value
        }
        
        XCTAssertEqual(targetValue, 0)
    }
    
    func testSynchronizedResult() {
        let atomic = Atomic(0)
        
        let result = atomic.synchronized { value in
            "\(value)"
        }
        
        XCTAssertEqual(result, "0")
    }
    
    func testModify() {
        let atomic = Atomic(0)
        
        let expectedValue = 1
        
        atomic.modify { value in
            value = expectedValue
        }
        
        XCTAssertEqual(atomic.synchronized { $0 }, expectedValue)
    }
    
    func testModifyResult() {
        let atomic = Atomic(0)
        
        let result: String = atomic.modify { value in
            value = 1
            return "\(value)"
        }
        
        XCTAssertEqual(result, "1")
    }
    
    func testValueGetterAndSetter() {
        let atomic = Atomic(0)
        
        let expectedValue = 1
        
        atomic.value = expectedValue
        let resultValue = atomic.value
        
        XCTAssertEqual(resultValue, expectedValue)
    }
    
    func testSwap() {
        let initialValue = 0
        let expectedValue = 1
        
        let atomic = Atomic(initialValue)

        let oldValue = atomic.swap(expectedValue)
        let newValue = atomic.value
        
        XCTAssertEqual(oldValue, initialValue)
        XCTAssertEqual(newValue, expectedValue)
    }
    
    func testAsync() {
        let atomic = Atomic(0)
        
        let expectation = self.expectation(description: "async modify")
        
        atomic.modify { value in
            value = 1
            sleep(1)
        }
        
        DispatchQueue.globalQueue().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(atomic.synchronized { $0 }, 1)
            
            atomic.modify { value in
                value += 1
            }
            
            XCTAssertEqual(atomic.synchronized { $0 }, 2)
            
            atomic.modify { value in
                value += 1
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(atomic.synchronized { $0 }, 3)
        }
    }
}
