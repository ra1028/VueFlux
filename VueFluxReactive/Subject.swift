import VueFlux

/// A stream that able to both sends and receive values.
public final class Subject<Value>: Subscribable {
    /// A signal for subject.
    public private(set) lazy var signal = Signal(self)
    
    private lazy var observers = ThreadSafe(Storage<(Value) -> Void>())
    
    /// Map each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that to transform each values to a new value.
    ///
    /// - Returns: Signal to be sent new values.
    @inline(__always)
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return signal.map(transform)
    }
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive values on.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return subscribe(executor: executor, initialValue: nil, observer: observer)
    }
    
    /// Send arbitrary value to all subscribed observers.
    ///
    /// - Parameters:
    ///   - value: Value to send to all observers.
    public func send(value: Value) {
        observers.synchronized { observers in
            observers.forEach { $0(value) }
        }
    }
}

extension Subject {
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive values on.
    ///   - observer: A function to be received the values.
    ///   - initialValue: Initial value to be received just on subscribed.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(executor: Executor, initialValue: Value?, observer: @escaping (Value) -> Void) -> Subscription {
        return observers.modify { observers in
            let key = observers.append { value in
                executor.execute { observer(value) }
            }
            
            if let initialValue = initialValue {
                executor.execute { observer(initialValue) }
            }
            
            return AnySubscription { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
}
