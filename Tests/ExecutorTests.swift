import XCTest
@testable import VueFlux

final class ExecutorTests: XCTestCase {
    func testImmediateExcutor() {
        let excutor = Executor.immediate
        
        var value = 0
        
        excutor.execute { value = 1 }
        value = 2
        
        XCTAssertEqual(value, 2)
    }
    
    func testMainThreadExcutor() {
        let excutor = Executor.mainThread
        
        let expectation = self.expectation(description: "global default queue execute")
        
        DispatchQueue.global().async {
            excutor.execute {
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSerialMainThreadExcutor() {
        let excutor = Executor.mainThread
        
        let expectation = self.expectation(description: "serial main thread execute")
        
        var array = [Int]()
        
        let group = DispatchGroup()
        
        DispatchQueue.global().async(group: group) {
            excutor.execute {
                array.append(0)
            }
        }
        
        group.wait()
        
        DispatchQueue.global().async(group: group) {
            excutor.execute {
                array.append(1)
            }
            
            excutor.execute {
                array.append(2)
            }
        }
        
        group.wait()
        
        excutor.execute {
            array.append(3)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(array, [0, 1, 2, 3])
        }
    }
    
    func testDispatchQueueExcutor() {
        let dispatchQueue = DispatchQueue.global()
        dispatchQueue.suspend()
        
        let excutor = Executor.queue(dispatchQueue)
        
        let expectation = self.expectation(description: "multi global default queue execute")
        
        var value = 0
        
        let times = 5
        
        (1...times).forEach { currentTimes in
            excutor.execute {
                XCTAssertFalse(Thread.isMainThread)
                value += 1
                
                if currentTimes == times {
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertEqual(value, 0)
        
        dispatchQueue.resume()
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, times)
        }
    }
}
