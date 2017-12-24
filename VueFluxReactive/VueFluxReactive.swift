import VueFlux

/// A sink that to sends all values to signal.
public struct Sink<Value> {
    /// Create the signal that flows all values sent into the sink.
    public var signal: Signal<Value> {
        return .init(subject.subscribe(observer:))
    }
    
    private let subject = Subject<Value>()
    
    /// Send arbitrary value to the signal.
    ///
    /// - Parameters:u
    ///   - value: Value to send to the signal.
    public func send(value: Value) {
        subject.send(value: value)
    }
}

/// A signal that only able to receive values.
public struct Signal<Value>: Subscribable {
    public typealias Producer = (@escaping (Value) -> Void) -> Subscription
    
    private let producer: (@escaping (Value) -> Void) -> Subscription
    
    /// Create a signal with subscribed function.
    /// - Parameters:
    ///   - producer: A function of behavior when subscribed.
    public init(_ producer: @escaping Producer) {
        self.producer = producer
    }
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(observer: @escaping (Value) -> Void) -> Subscription {
        return producer(observer)
    }
}

/// A variable that able to change value and receive changes via signal.
public final class Variable<Value> {
    /// Create a constant which reflects the `self`.
    public var constant: Constant<Value> {
        return .init(variable: self)
    }
    
    /// Create a signal that flows current value at the time of subscribing and all value changes.
    public var signal: Signal<Value> {
        return .init { send in
            self._value.synchronized { value in
                send(value)
                return self.subject.subscribe(observer: send)
            }
        }
    }
    
    /// The current value.
    /// Setting this to a new value will send to signal.
    public var value: Value {
        get {
            return _value.value
        }
        set {
            _value.modify { value in
                value = newValue
                subject.send(value: newValue)
            }
        }
    }
    
    private let subject = Subject<Value>()
    private var _value: ThreadSafe<Value>
    
    /// Create a new variable with its initial value.
    public init(_ value: Value) {
        _value = .init(value)
    }
}

/// A constant that able to change value and receive changes via signal.
/// Changes are reflects from a variable.
public struct Constant<Value> {
    /// Create a signal that flows current value at the time of subscribing and all value changes.
    public var signal: Signal<Value> {
        return variable.signal
    }
    
    /// The current value.
    public var value: Value {
        return variable.value
    }
    
    private let variable: Variable<Value>
    
    /// Create a new constant with its initial value.
    public init(_ value: Value) {
        self.variable = .init(value)
    }

    /// Create a new constant with variable that to be reflected in `self`.
    public init(variable: Variable<Value>) {
        self.variable = variable
    }
}
