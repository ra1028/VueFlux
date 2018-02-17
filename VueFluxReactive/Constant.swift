/// Wrapper to make Variable read-only.
/// Observable value changes are reflects from its variable.
public struct Constant<Value> {
    /// Create a signal to forwards the current value at observation and the all value changes.
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
        variable = .init(value)
    }
    
    /// Create a new constant with a variable.
    ///
    /// - Parameters:
    ///   - variable: A variable to be reflected in `self`.
    public init(variable: Variable<Value>) {
        self.variable = variable
    }
}
