import VueFlux

public final class Subject<Value> {
    public private(set) lazy var signal = Signal(self)
    
    private let observers = ThreadSafe(Storage<(Value) -> Void>())
    
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return observers.modify { observers in
            let key = observers.append { value in
                executor.execute { observer(value) }
            }
            
            return .init { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
    
    /// Send given value to all subscribed observers.
    ///
    /// - Parameters:
    ///   - value: Value to send to all observers.
    public func send(value: Value) {
        observers.synchronized { observers in
            observers.forEach { $0(value) }
        }
    }
}
