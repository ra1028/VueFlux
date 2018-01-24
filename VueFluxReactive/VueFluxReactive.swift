import VueFlux

/// Represents the wrapper around a function to forward values to signal.
public struct Sink<Value> {
    /// Create the signal that flows all values sent into the sink.
    public var signal: Signal<Value> {
        return .init(stream.add(observer:))
    }
    
    private let stream = Stream<Value>()
    
    /// Create a sink.
    public init() {}
    
    /// Send arbitrary value to the signal.
    ///
    /// - Parameters:
    ///   - value: A value to send to the signal.
    public func send(value: Value) {
        stream.send(value: value)
    }
}

/// A stream that can be sending values over time.
public struct Signal<Value>: Subscribable {
    public typealias Producer = (@escaping (Value) -> Void) -> Subscription
    
    private let producer: (@escaping (Value) -> Void) -> Subscription
    
    /// Create a signal with subscribed function.
    ///
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

/// Represents an observable value that can be change directly.
public final class Variable<Value> {
    /// Create a constant which reflects the `self`.
    public var constant: Constant<Value> {
        return .init(variable: self)
    }
    
    /// Create a signal that forwards current value at the time of subscribing and all value changes.
    public var signal: Signal<Value> {
        return .init { send in
            self._value.synchronized { value in
                send(value)
                return self.stream.add(observer: send)
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
                stream.send(value: newValue)
            }
        }
    }
    
    private let stream = Stream<Value>()
    private var _value: ThreadSafe<Value>
    
    /// Create a new variable with its initial value.
    ///
    /// - Parameters:
    ///   - value: An initial value.
    public init(_ value: Value) {
        _value = .init(value)
    }
}

/// Wrapper to make Variable read-only.
/// Observable value changes are reflects from its variable.
public struct Constant<Value> {
    /// Create a signal that forwards current value at the time of subscribing and all value changes.
    public var signal: Signal<Value> {
        return variable.signal
    }
    
    /// The current value.
    public var value: Value {
        return variable.value
    }
    
    private let variable: Variable<Value>
    
    /// Create a new constant with its initial value.
    ///
    /// - Parameters:
    ///   - value: An initial value.
    public init(_ value: Value) {
        self.variable = .init(value)
    }

    /// Create a new constant with a variable.
    ///
    /// - Parameters:
    ///   - variable: A variable to be reflected in `self`.
    public init(variable: Variable<Value>) {
        self.variable = variable
    }
}
