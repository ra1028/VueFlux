import XCTest
@testable import VueFlux
@testable import VueFluxReactive

protocol LockProtocol {
    func lock()
    func unlock()
}

extension VueFlux.Lock: LockProtocol {}
extension VueFluxReactive.Lock: LockProtocol {}

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
        
        func runNonRecursiveTest<Lock: LockProtocol>(for lock: Lock) {
            runTest { criticalSection in
                lock.lock()
                criticalSection()
                lock.unlock()
            }
        }
        
        func runRecursiveTest<Lock: LockProtocol>(for lock: Lock) {
            runTest { criticalSection in
                lock.lock()
                criticalSection()
                lock.unlock()
            }
        }
        
        runNonRecursiveTest(for: VueFlux.Lock(recursive: false))
        runNonRecursiveTest(for: VueFluxReactive.Lock(recursive: false))
        runNonRecursiveTest(for: VueFlux.Lock(recursive: true))
        runNonRecursiveTest(for: VueFluxReactive.Lock(recursive: true))
        runNonRecursiveTest(for: VueFlux.Lock(recursive: false, usePosixThreadMutexForced: true))
        runNonRecursiveTest(for: VueFluxReactive.Lock(recursive: false, usePosixThreadMutexForced: true))
        runNonRecursiveTest(for: VueFlux.Lock(recursive: true, usePosixThreadMutexForced: true))
        runNonRecursiveTest(for: VueFluxReactive.Lock(recursive: true, usePosixThreadMutexForced: true))
    }
}
