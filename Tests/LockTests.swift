import XCTest
@testable import VueFlux

final class LockTests: XCTestCase {
    func testLock() {
        func runTest(synchronized: @escaping (() -> Void) -> Void) {
            let queue = DispatchQueue(label: "testLock", attributes: .concurrent)
            let group = DispatchGroup()
            
            var value = 0
            for _ in (1...100) {
                queue.async(group: group) {
                    synchronized {
                        value += 1
                        value -= 1
                        value += 2
                        value -= 2
                    }
                }
            }
            
            _ = group.wait(timeout: .now() + 10)
            XCTAssertEqual(value, 0)
        }
        
        let lock = Lock(recursive: false)
        
        runTest { criticalSection in
            lock.lock()
            criticalSection()
            lock.unlock()
        }
        
        let recursiveLock = Lock(recursive: true)
        
        runTest { criticalSection in
            recursiveLock.lock()
            recursiveLock.lock()
            criticalSection()
            recursiveLock.unlock()
            recursiveLock.unlock()
        }
    }
}
