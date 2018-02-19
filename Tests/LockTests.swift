import XCTest
@testable import VueFlux

final class LockTests: XCTestCase {
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    func testOSUnfairLock() {
        let lock = Lock._init(usePosixThreadMutexForced: false)
        
        let queue = DispatchQueue(label: "testOSUnfairLock", attributes: .concurrent)
        let group = DispatchGroup()
        
        var value = 0
        for _ in (1...100) {
            queue.async(group: group) {
                lock.lock()
                value += 1
                value -= 1
                value += 2
                value -= 2
                lock.unlock()
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        XCTAssertEqual(value, 0)
    }
    
    func testPosixThreadMutex() {
        let lock = Lock._init(usePosixThreadMutexForced: true)
        
        let queue = DispatchQueue(label: "testPosixThreadMutex", attributes: .concurrent)
        let group = DispatchGroup()
        
        var value = 0
        for _ in (1...100) {
            queue.async(group: group) {
                lock.lock()
                value += 1
                value -= 1
                value += 2
                value -= 2
                lock.unlock()
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        XCTAssertEqual(value, 0)
    }
}
