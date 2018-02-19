import VueFlux

/// Represents the wrapper around a function to forward values to signal.
public final class Sink<Value> {
    private typealias Observers = Storage<(Value) -> Void>
    
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
    
    private let observers = AtomicReference(Observers())
    private let _send: AtomicReference<(Observers, Value) -> Void>
    
    /// Initialize a sink.
    public init() {
        _send = .init { observers, value in
            for observer in observers {
                observer(value)
            }
        }
    }
    
    /// Send arbitrary value to the signal.
    ///
    /// - Parameters:
    ///   - value: A value to send to the signal.
    public func send(value: Value) {
        _send.synchronized { send in
            send(observers.value, value)
        }
    }
}
