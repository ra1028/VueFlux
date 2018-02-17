/// Represents the wrapper around a function to forward values to signal.
public struct Sink<Value> {
    /// Create the signal that flows all values sent into the sink.
    public var signal: Signal<Value> {
        return .init(stream.observe(_:))
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
