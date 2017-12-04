import VueFlux

/// A variable that able to change value and observe changes.
public final class Mutable<Value>: Subscribable {
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
            _value.modify { value in
                value = newValue
                subject.send(value: value)
            }
        }
    }
    
    private let subject = Subject<Value>()
    private let _value: ThreadSafe<Value>
    
    /// Initialze a new mutable with its initial value.
    public init(value: Value) {
        self._value = .init(value)
    }
    
    /// Map current value and each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that transform current value and each values to a new value.
    ///
    /// - Returns: An Immutable that have transformed value.
    @inline(__always)
    public func map<T>(_ transform: @escaping (Value) -> T) -> Immutable<T> {
        return immutable.map(transform)
    }
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive values on.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return _value.synchronized { value in
            subject.subscribe(executor: executor, initialValue: value, observer: observer)
        }
    }
}
