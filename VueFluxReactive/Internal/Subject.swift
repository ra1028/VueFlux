import VueFlux

/// A stream that able to both sends and receive values.
final class Subject<Value>: Subscribable {
    private lazy var observers = ThreadSafe(Storage<(Value) -> Void>())
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:z
    ///   - executor: An executor to receive values on.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return observers.modify { observers in
            let key = observers.append { value in
                executor.execute { observer(value) }
            }
            
            return AnySubscription { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
    
    /// Send arbitrary value to all subscribed observers.
    ///
    /// - Parameters:
    ///   - value: Value to send to all observers.
    func send(value: Value) {
        observers.synchronized { observers in
            observers.forEach { $0(value) }
        }
    }
}
