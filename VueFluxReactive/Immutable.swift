import VueFlux

public final class Immutable<Value>: ReactiveVariable {
    private let _value: () -> Value
    private let _signal: () -> Signal<Value>
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    /// The current value.
    public var value: Value {
        return _value()
    }
    
    /// A signal that will send the value changes.
    public var signal: Signal<Value> {
        return _signal()
    }
    
    /// Initialize with mutable.
    public convenience init(_ mutable: Mutable<Value>) {
        self.init(mutable) { $0 }
    }
    
    private init<Variable: ReactiveVariable, T>(_ variable: Variable, _ transform: @escaping (T) -> Value) where Variable.Value == T {
        _value = { transform(variable.value) }
        _signal = { variable.signal.map(transform) }
        _subscribe = { executor, observer in
            variable.subscribe(executor: executor) { value in
                observer(transform(value))
            }
        }
    }
    
    /// Map current value and each value to a new value.
    ///
    /// - parameters:
    ///   - transform: A function that transform current value and each value to a new value.
    ///
    /// - returns: A Immutable that have transformed value.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Immutable<T> {
        return .init(self, transform)
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
        return _subscribe(executor, observer)
    }
}
