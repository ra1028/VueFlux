import Foundation

/// The lock that coordinates the operation of multiple threads of execution.
/// Use `os_unfair_lock` on supported platforms, otherwise pthread mutex instead.
class Lock {
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    private final class OSUnfairLock: Lock {
        private let _lock = os_unfair_lock_t.allocate(capacity: 1)
        
        override init() {
            _lock.initialize(to: os_unfair_lock())
            super.init()
        }
        
        deinit {
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        override func lock() {
            os_unfair_lock_lock(_lock)
        }
        
        override func unlock() {
            os_unfair_lock_unlock(_lock)
        }
    }
    
    private final class PosixThreadMutex: Lock {
        private let _lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        
        init(recursive: Bool) {
            _lock.initialize(to: pthread_mutex_t())
            
            if recursive {
                let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
                attr.initialize(to: pthread_mutexattr_t())
                pthread_mutexattr_init(attr)
                pthread_mutexattr_settype(attr, PTHREAD_MUTEX_RECURSIVE)
                
                defer {
                    pthread_mutexattr_destroy(attr)
                    attr.deinitialize()
                    attr.deallocate(capacity: 1)
                }
                
                let result = pthread_mutex_init(_lock, attr)
                assert(result == 0)
            } else {
                let result = pthread_mutex_init(_lock, nil)
                assert(result == 0)
            }
        }
        
        deinit {
            let result = pthread_mutex_destroy(_lock)
            assert(result == 0)
            
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        override func lock() {
            let result = pthread_mutex_lock(_lock)
            assert(result == 0)
        }
        
        override func unlock() {
            let result = pthread_mutex_unlock(_lock)
            assert(result == 0)
        }
    }
    
    static func initialize(recursive: Bool) -> Lock {
        if #available(*, iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0), !recursive {
            return OSUnfairLock()
        }
        return PosixThreadMutex(recursive: recursive)
    }
    
    private init() {}
    
    func lock() {
        fatalError()
    }
    
    func unlock() {
        fatalError()
    }
    
    @inline(__always)
    @discardableResult
    func synchronized<Result>(_ function: () throws -> Result) rethrows -> Result {
        lock()
        defer { unlock() }
        return try function()
    }
}
