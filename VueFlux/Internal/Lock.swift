import Foundation

class Lock {
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    final class OSUnfairLock: Lock {
        private let _lock = os_unfair_lock_t.allocate(capacity: 1)
        
        override init() {
            _lock.initialize(to: os_unfair_lock())
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
            pthread_mutex_init(_lock, nil)
        }
        
        deinit {
            pthread_mutex_destroy(_lock)
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        override func lock() {
            pthread_mutex_lock(_lock)
        }
        
        override func unlock() {
            pthread_mutex_unlock(_lock)
        }
    }
    
    static func _init(usePosixThreadMutexForced: Bool) -> Lock {
        if #available(*, iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0), !usePosixThreadMutexForced {
            return OSUnfairLock()
        } else {
            return PosixThreadMutex()
        }
    }
    
    private init() {}

    func lock() { fatalError() }
    func unlock() { fatalError() }
}
