import XCTest
@testable import VueFlux

final class ThreadSafeTests: XCTestCase {
    func testSynchronized() {
        let threadSafe = ThreadSafe(0)
        
        var targetValue = 1
        
        threadSafe.synchronized { value in
            targetValue = value
        }
        
        XCTAssertEqual(targetValue, 0)
    }
    
    func testSynchronizedResult() {
        let threadSafe = ThreadSafe(0)
        
        let result = threadSafe.synchronized { value in
            "\(value)"
        }
        
        XCTAssertEqual(result, "0")
    }
    
    func testModify() {
        let threadSafe = ThreadSafe(0)
        
        let expectedValue = 1
        
        threadSafe.modify { value in
            value = expectedValue
        }
        
        XCTAssertEqual(threadSafe.synchronized { $0 }, expectedValue)
    }
    
    func testModifyResult() {
        let threadSafe = ThreadSafe(0)
        
        let result: String = threadSafe.modify { value in
            value = 1
            return "\(value)"
        }
        
        XCTAssertEqual(result, "1")
    }
    
    func testValueGetterAndSetter() {
        let threadSafe = ThreadSafe(0)
        
        let expectedValue = 1
        
        threadSafe.value = expectedValue
        let resultValue = threadSafe.value
        
        XCTAssertEqual(resultValue, expectedValue)
    }
    
    func testSwap() {
        let initialValue = 0
        let expectedValue = 1
        
        let threadSafe = ThreadSafe(initialValue)

        let oldValue = threadSafe.swap(expectedValue)
        let newValue = threadSafe.value
        
        XCTAssertEqual(oldValue, initialValue)
        XCTAssertEqual(newValue, expectedValue)
    }
    
    func testAsync() {
        let threadSafe = ThreadSafe(0)
        
        let expectation = self.expectation(description: "async modify")
        
        threadSafe.modify { value in
            value = 1
            sleep(1)
        }
        
        DispatchQueue.globalQueue().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(threadSafe.synchronized { $0 }, 1)
            
            threadSafe.modify { value in
                value += 1
            }
            
            XCTAssertEqual(threadSafe.synchronized { $0 }, 2)
            
            threadSafe.modify { value in
                value += 1
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(threadSafe.synchronized { $0 }, 3)
        }
    }
}
