import class VueFlux.AtomicReference

/// Represents an observable value that can be change directly.
public final class Variable<Value> {
    /// Create a constant which reflects the `self`.
    public var constant: Constant<Value> {
        return .init(variable: self)
    }
    
    /// Create a signal to forwards the current value at observation and the all value changes.
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
    private var _value: AtomicReference<Value>
    
    /// Create a new variable with its initial value.
    ///
    /// - Parameters:
    ///   - value: An initial value.
    public init(_ value: Value) {
        _value = .init(value)
    }
}
