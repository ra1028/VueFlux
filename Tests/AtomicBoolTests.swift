import XCTest
@testable import VueFlux
@testable import VueFluxReactive

protocol AtomicBoolProtocol: ExpressibleByBooleanLiteral {
    var value: Bool { get }
    
    func compareAndSwapBarrier(old: Bool, new: Bool) -> Bool
}

extension VueFlux.AtomicBool: AtomicBoolProtocol {}
extension VueFluxReactive.AtomicBool: AtomicBoolProtocol {}

final class AtomicBoolTests: XCTestCase {
    func testAtomicBool() {
        func runTest<AtomicBool: AtomicBoolProtocol>(for type: AtomicBool.Type) {
            let atomicBool: AtomicBool = true
            
            XCTAssertTrue(atomicBool.value)
            
            let result1 = atomicBool.compareAndSwapBarrier(old: true, new: false)
            
            XCTAssertFalse(atomicBool.value)
            XCTAssertTrue(result1)
            
            let result2 = atomicBool.compareAndSwapBarrier(old: true, new: false)
            
            XCTAssertFalse(atomicBool.value)
            XCTAssertFalse(result2)
        }
        
        runTest(for: VueFlux.AtomicBool.self)
        runTest(for: VueFluxReactive.AtomicBool.self)
    }
}
