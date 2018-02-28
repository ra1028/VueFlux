import VueFlux

/// Represents the wrapper around a function to forward values to signal.
public final class Sink<Value> {
    /// Create the signal that flows all values sent into the sink.
    public var signal: Signal<Value> {
        return .init { send in
            let key = self.observers.modify { observers in
                observers.add(send)
            }
            
            return AnyDisposable { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
    
    private let observers = AtomicReference(Storage<(Value) -> Void>())
    private let sendLock = Lock(recursive: false)
    
    /// Initialize a sink.
    public init() {}
    
    /// Send arbitrary value to the signal.
    ///
    /// - Parameters:
    ///   - value: A value to send to the signal.
    public func send(value: Value) {
        sendLock.lock()
        defer { sendLock.unlock() }
        
        for observer in observers.value {
            observer(value)
        }
    }
}
