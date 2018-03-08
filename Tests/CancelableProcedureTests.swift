import XCTest
@testable import VueFlux
@testable import VueFluxReactive

private protocol CancelableProcedureProtocol {
    associatedtype Value
    
    var isCanceled: Bool { get }
    
    init(_ execute: @escaping (Value) -> Void)
    func execute(with value: @autoclosure () -> Value)
    func cancel()
}

extension VueFlux.CancelableProcedure: CancelableProcedureProtocol {}
extension VueFluxReactive.CancelableProcedure: CancelableProcedureProtocol {}

final class CancelableProcedureTests: XCTestCase {
    func testVoidProcedure() {
        func runTest<CancelableProcedure: CancelableProcedureProtocol>(for type: CancelableProcedure.Type) where CancelableProcedure.Value == Void {
            
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
        
        runTest(for: VueFlux.CancelableProcedure<Void>.self)
        runTest(for: VueFluxReactive.CancelableProcedure<Void>.self)
    }
    
    func testValueWorkItem() {
        func runTest<CancelableProcedure: CancelableProcedureProtocol>(for type: CancelableProcedure.Type) where CancelableProcedure.Value == Int {
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
        
        runTest(for: VueFlux.CancelableProcedure<Int>.self)
        runTest(for: VueFluxReactive.CancelableProcedure<Int>.self)
    }
    
    func testCancelProcedureAsync() {
        func runTest<CancelableProcedure: CancelableProcedureProtocol>(for type: CancelableProcedure.Type) where CancelableProcedure.Value == Int {
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
        
        runTest(for: VueFlux.CancelableProcedure<Int>.self)
        runTest(for: VueFluxReactive.CancelableProcedure<Int>.self)
    }
    
    func testExecuteVoidProcedure() {
        var value = 0
        let vueFluxProcedure = VueFlux.CancelableProcedure<Void> {
            value = 1
        }
        
        let vueFluxReactiveProcedure = VueFluxReactive.CancelableProcedure<Void> {
            value = 2
        }
        
        vueFluxProcedure.execute()
        vueFluxReactiveProcedure.execute()
        
        XCTAssertEqual(value, 2)
    }
}
