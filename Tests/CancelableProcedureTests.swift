import XCTest
@testable import VueFlux

final class CancelableProcedureTests: XCTestCase {
    func testVoidProcedure() {
        var value = 0
        
        let procedure = CancelableProcedure {
            value += 1
        }
        
        XCTAssertEqual(value, 0)
        
        procedure.execute(with: ())
        
        XCTAssertEqual(value, 1)
        
        procedure.cancel()
        procedure.execute(with: ())
        
        XCTAssertEqual(value, 1)
        
        procedure.cancel()
        procedure.execute(with: ())
        
        XCTAssertEqual(value, 1)
    }
    
    func testValueWorkItem() {
        var value = 0
        
        let procedure = CancelableProcedure { int in
            value = int
        }
        
        XCTAssertEqual(value, 0)
        
        procedure.execute(with: 1)
        
        XCTAssertFalse(procedure.isCanceled)
        XCTAssertEqual(value, 1)
        
        procedure.cancel()
        procedure.execute(with: 2)
        
        XCTAssertTrue(procedure.isCanceled)
        XCTAssertEqual(value, 1)
        
        procedure.cancel()
        procedure.execute(with: 3)
        
        XCTAssertTrue(procedure.isCanceled)
        XCTAssertEqual(value, 1)
    }
    
    func testCancelProcedureAsync() {
        let queue = DispatchQueue(label: "testCancelProcedureAsync")
        
        var value = 0
        
        let expectation = self.expectation(description: "testCancelProcedureAsync")
        
        let procedure = CancelableProcedure { int in
            value = int
        }
        
        XCTAssertFalse(procedure.isCanceled)
        
        queue.suspend()
        
        queue.async {
            procedure.execute(with: 1)
        }
        
        procedure.cancel()
        queue.resume()
        
        queue.async(execute: expectation.fulfill)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(procedure.isCanceled)
            XCTAssertEqual(value, 0)
        }
    }
    
    func testExecuteVoidProcedure() {
        var value = 0
        
        let procedure = CancelableProcedure<Void> {
            value = 1
        }
        
        procedure.execute()
        
        XCTAssertEqual(value, 1)
    }
}
