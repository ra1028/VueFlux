import Foundation

/// Non-recursive thread lock.
/// Use `os_unfair_lock` on supported platforms, otherwise pthread mutex instead.
class Lock {
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    final class OSUnfairLock: Lock {
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
    
    final class PosixThreadMutex: Lock {
        private let _lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        
        override init() {
            _lock.initialize(to: pthread_mutex_t())
            
            let result = pthread_mutex_init(_lock, nil)
            assert(result == 0)
            
            super.init()
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
    
    static func initialize() -> Lock {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            if #available(*, iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0) {
                return OSUnfairLock()
            }
        #endif
        return PosixThreadMutex()
    }
    
    private init() {}
    
    func lock() {
        fatalError()
    }
    
    func unlock() {
        fatalError()
    }
}
