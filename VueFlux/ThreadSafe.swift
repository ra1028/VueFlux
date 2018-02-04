/// An thread-safe value wrapper.
public final class ThreadSafe<Value> {
    private var _value: Value
    private let lock: Lock
    
    /// Synchronized value getter and setter
    public var value: Value {
        get { return synchronized { $0 } }
        set { modify { $0 = newValue } }
    }
    
    /// Initialize with the given initial value.
    ///
    /// - Parameters:
    ///   - value: Initial value.
    ///   - recursive: A Bool value indicating whether lock is recursive.
    public init(_ value: Value, recursive: Bool = false) {
        _value = value
        lock = .initialize(recursive: recursive)
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
