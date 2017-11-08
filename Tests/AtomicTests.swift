import XCTest
@testable import VueFlux

final class AtomicTests: XCTestCase {
    private let atomic = Atomic<Int>(0)
    
    func testSynchronized() {
        var targetValue = 100
        
        atomic.synchronized { value in
            targetValue = value
        }
        
        XCTAssertEqual(targetValue, 0)
    }
    
    func testSynchronizedResult() {
        let result = atomic.synchronized { value in
            "\(value)"
        }
        
        XCTAssertEqual(result, "0")
    }
    
    func testModify() {
        let expectedValue = 1
        
        atomic.modify { value in
            value = expectedValue
        }
        
        XCTAssertEqual(atomic.synchronized { $0 }, expectedValue)
    }
    
    func testModifyResult() {
        let result: String = atomic.modify { value in
            value = 100
            return "\(value)"
        }
        
        XCTAssertEqual(result, "100")
    }
    
    func testAsync() {
        let expectation = self.expectation(description: "async modify")
        
        atomic.modify { value in
            value = 200
            sleep(1)
        }
        
        DispatchQueue.globalQueue().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.atomic.synchronized { $0 }, 200)
            
            self.atomic.modify { value in
                value += 100
            }
            
            XCTAssertEqual(self.atomic.synchronized { $0 }, 300)
            
            self.atomic.modify { value in
                value += 100
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(self.atomic.synchronized { $0 }, 400)
        }
    }
}
