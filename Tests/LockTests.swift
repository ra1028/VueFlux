import XCTest
@testable import VueFlux

final class LockTests: XCTestCase {
    func testNonRecursiveLock() {
        let lock = Lock.initialize(recursive: false)
        var value = 0
        
        lock.lock()
        value = 1
        lock.unlock()
        
        XCTAssertEqual(value, 1)
    }
    
    func testRecursiveLock() {
        let lock = Lock.initialize(recursive: true)
        var value = 0
        
        lock.lock()
        lock.lock()
        value = 1
        lock.unlock()
        lock.unlock()
        
        XCTAssertEqual(value, 1)
    }
}
