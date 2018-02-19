import XCTest
@testable import VueFlux

final class AtomicReferenceTests: XCTestCase {
    func testSynchronized() {
        let atomicReference = AtomicReference(0)
        
        var targetValue = 1
        
        atomicReference.synchronized { value in
            targetValue = value
        }
        
        XCTAssertEqual(targetValue, 0)
    }
    
    func testSynchronizedResult() {
        let atomicReference = AtomicReference(0)
        
        let result = atomicReference.synchronized { value in
            "\(value)"
        }
        
        XCTAssertEqual(result, "0")
    }
    
    func testModify() {
        let atomicReference = AtomicReference(0)
        
        let expectedValue = 1
        
        atomicReference.modify { value in
            value = expectedValue
        }
        
        XCTAssertEqual(atomicReference.synchronized { $0 }, expectedValue)
    }
    
    func testModifyResult() {
        let atomicReference = AtomicReference(0)
        
        let result: String = atomicReference.modify { value in
            value = 1
            return "\(value)"
        }
        
        XCTAssertEqual(result, "1")
    }
    
    func testValueGetterAndSetter() {
        let atomicReference = AtomicReference(0)
        
        let expectedValue = 1
        
        atomicReference.value = expectedValue
        let resultValue = atomicReference.value
        
        XCTAssertEqual(resultValue, expectedValue)
    }
    
    func testSwap() {
        let initialValue = 0
        let expectedValue = 1
        
        let atomicReference = AtomicReference(initialValue)

        let oldValue = atomicReference.swap(expectedValue)
        let newValue = atomicReference.value
        
        XCTAssertEqual(oldValue, initialValue)
        XCTAssertEqual(newValue, expectedValue)
    }
    
    func testAsync() {
        let atomicReference = AtomicReference(0)
        
        let expectation = self.expectation(description: "testAsync")
        
        atomicReference.modify { value in
            value = 1
            sleep(1)
        }
        
        DispatchQueue.globalDefault().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(atomicReference.synchronized { $0 }, 1)
            
            atomicReference.modify { value in
                value += 1
            }
            
            XCTAssertEqual(atomicReference.synchronized { $0 }, 2)
            
            atomicReference.modify { value in
                value += 1
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(atomicReference.synchronized { $0 }, 3)
        }
    }
    
    func testPosixThreadMutex() {
        let atomicReference = AtomicReference(0, usePosixThreadLockForeced: true)
        
        let queue = DispatchQueue(label: "testPosixThreadMutex", attributes: .concurrent)
        let group = DispatchGroup()
        
        for _ in (1...100) {
            queue.async(group: group) {
                atomicReference.modify { value in
                    value += 1
                    value -= 1
                    value += 2
                    value -= 2
                }
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        XCTAssertEqual(atomicReference.value, 0)
    }
}
