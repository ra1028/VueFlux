import Foundation

/// An thread-safe value wrapper.
public final class ThreadSafe<Value> {
    private var _value: Value
    private let lock: NSLocking = {
        if #available(*, iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0) {
            return OSUnfairLock()
        }
        return PosixThreadMutex()
    }()
    
    /// Synchronized value getter and setter
    public var value: Value {
        get { return synchronized { $0 } }
        set { modify { $0 = newValue } }
    }
    
    /// Initialize with the given initial value.
    ///
    /// - Parameters:
    ///   - value: Initial value.
    public init(_ value: Value) {
        _value = value
    }
    
    /// Perform a given action with current value thread-safely.
    ///
    /// - Parameters:
    ///   - function: Arbitrary function with current value.
    ///
    /// - Returns: Result value of action.
    @discardableResult
    public func synchronized<Result>(_ function: (Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try function(_value)
    }
    
    /// Modifies the value thread-safely.
    ///
    /// - Parameters:
    ///   - function: Arbitrary modification function for current value.
    ///
    /// - Returns: Result value of modification action.
    @discardableResult
    public func modify<Result>(_ function: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try function(&_value)
    }
    
    /// Set the new value and Returns old value.
    ///
    /// - Parameters:
    ///   - newValue: A new value.
    ///
    /// - Returns: An old value.
    @discardableResult
    public func swap(_ newValue: Value) -> Value {
        return modify { value in
            let oldValue = value
            value = newValue
            return oldValue
        }
    }
}

private extension ThreadSafe {
    /// Fast non-recursive thread lock.
    /// Use in supported OS version only.
    @available(iOS 10.0, *)
    @available(macOS 10.12, *)
    @available(tvOS 10.0, *)
    @available(watchOS 3.0, *)
    final class OSUnfairLock: NSLocking {
        private let _lock = os_unfair_lock_t.allocate(capacity: 1)
        
        init() {
            _lock.initialize(to: os_unfair_lock())
        }
        
        deinit {
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        func lock() {
            os_unfair_lock_lock(_lock)
        }
        
        func unlock() {
            os_unfair_lock_unlock(_lock)
        }
    }
    
    /// Non-recursive thread lock.
    /// Use in OS that `os_unfair_lock` not available.
    final class PosixThreadMutex: NSLocking {
        private let _lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        
        init() {
            _lock.initialize(to: pthread_mutex_t())
            
            let result = pthread_mutex_init(_lock, nil)
            assert(result == 0)
        }
        
        deinit {
            let result = pthread_mutex_destroy(_lock)
            assert(result == 0)
            
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        func lock() {
            let result = pthread_mutex_lock(_lock)
            assert(result == 0)
        }
        
        func unlock() {
            let result = pthread_mutex_unlock(_lock)
            assert(result == 0)
        }
    }
}
