import VueFlux

/// A variable that able to observe its value changes.
public final class Immutable<Value>: Subscribable {
    /// The current value.
    public var value: Value {
        return _value()
    }
    
    /// A signal that will send the value changes.
    public let signal: Signal<Value>
    
    private let _value: () -> Value
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    /// Initialize a immutable from mutable.
    public convenience init(_ mutable: Mutable<Value>) {
        self.init({ mutable.value }, mutable.signal) { executor, observer in
            mutable.subscribe(executor: executor) { value in
                observer(value)
            }
        }
    }
    
    private init(
        _ value: @escaping () -> Value,
        _ signal: Signal<Value>,
        _ subscribe: @escaping (Executor, @escaping (Value) -> Void) -> Subscription) {
        self.signal = signal
        _value = value
        _subscribe = subscribe
    }
    
    /// Map current value and each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that transform current value and each values to a new value.
    ///
    /// - Returns: A Immutable that have transformed value.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Immutable<T> {
        return .init({ transform(self.value) }, signal.map(transform)) { executor, observer in
            self.subscribe(executor: executor) { value in
                observer(transform(value))
            }
        }
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
        return _subscribe(executor, observer)
    }
}
