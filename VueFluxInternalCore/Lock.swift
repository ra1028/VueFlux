import Foundation

/// Coordinates the operation of multiple threads of execution.
struct Lock {
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    private final class OSUnfairLock: NSLocking {
        private let _lock = os_unfair_lock_t.allocate(capacity: 1)
        
        init() {
            _lock.initialize(to: os_unfair_lock())
        }
        
        deinit {
            _lock.deinitialize(count: 1)
            _lock.deallocate()
        }
        
        func lock() {
            os_unfair_lock_lock(_lock)
        }
        
        func unlock() {
            os_unfair_lock_unlock(_lock)
        }
    }
    
    private final class PosixThreadMutex: NSLocking {
        private let _lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        
        init(recursive: Bool = false) {
            _lock.initialize(to: pthread_mutex_t())
            
            if recursive {
                let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
                attributes.initialize(to: pthread_mutexattr_t())
                pthread_mutexattr_init(attributes)
                pthread_mutexattr_settype(attributes, Int32(PTHREAD_MUTEX_RECURSIVE))
                pthread_mutex_init(_lock, attributes)
                
                pthread_mutexattr_destroy(attributes)
                attributes.deinitialize(count: 1)
                attributes.deallocate()
            } else {
                pthread_mutex_init(_lock, nil)
            }
        }
        
        deinit {
            pthread_mutex_destroy(_lock)
            _lock.deinitialize(count: 1)
            _lock.deallocate()
        }
        
        func lock() {
            pthread_mutex_lock(_lock)
        }
        
        func unlock() {
            pthread_mutex_unlock(_lock)
        }
    }
    
    private let inner: NSLocking
    
    /// Attempts to acquire a lock, blocking a thread’s execution until the lock can be acquired.
    func lock() {
        inner.lock()
    }
    
    /// Relinquishes a previously acquired lock.
    func unlock() {
        inner.unlock()
    }
    
    /// Create a lock.
    ///
    /// - Parameters:
    ///   - recursive: A Bool value indicating whether locking is recursive.
    ///   - usePosixThreadMutexForced: Force to use Posix thread mutex.
    init(recursive: Bool, usePosixThreadMutexForced: Bool = false) {
        if #available(*, iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0), !usePosixThreadMutexForced, !recursive {
            inner = OSUnfairLock()
        } else {
            inner = PosixThreadMutex(recursive: recursive)
        }
    }
}
