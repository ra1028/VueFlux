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
