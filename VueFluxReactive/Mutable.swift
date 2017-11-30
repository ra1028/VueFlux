import VueFlux

public final class Mutable<Value>: ReactiveVariable {
    /// A signal that will send the value changes.
    public var signal: Signal<Value> {
        return subject.signal
    }
    
    /// A immutable which reflects the `self`.
    public private(set) lazy var immutable = Immutable<Value>(self)
    
    /// The current value.
    /// Setting this to a new value will send to all observers.
    public var value: Value {
        get {
            return _value.value
        }
        set {
            _value.value = newValue
            subject.send(value: value)
        }
    }
    
    private let subject = Subject<Value>()
    private let _value: ThreadSafe<Value>
    
    /// Initialze with a initial value.
    public init(value: Value) {
        self._value = .init(value)
    }
    
    /// Map current value and each value to a new value.
    ///
    /// - parameters:
    ///   - transform: A function that transform current value and each value to a new value.
    ///
    /// - returns: A Immutable that have transformed value.
    @inline(__always)
    public func map<T>(_ transform: @escaping (Value) -> T) -> Immutable<T> {
        return immutable.map(transform)
    }
    
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return _value.synchronized { value in
            subject.subscribe(executor: executor, initialValue: value, observer: observer)
        }
    }
}
