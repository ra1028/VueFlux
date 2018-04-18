import XCTest
@testable import VueFlux

final class AtomicBoolTests: XCTestCase {
    func testAtomicBool() {
        let atomicBool: AtomicBool = true
        
        XCTAssertTrue(atomicBool.value)
        
        let result1 = atomicBool.compareAndSwapBarrier(old: true, new: false)
        
        XCTAssertFalse(atomicBool.value)
        XCTAssertTrue(result1)
        
        let result2 = atomicBool.compareAndSwapBarrier(old: true, new: false)
        
        XCTAssertFalse(atomicBool.value)
        XCTAssertFalse(result2)
    }
}
