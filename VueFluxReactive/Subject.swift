import VueFlux

public final class Subject<Value>: Subscribable {
    /// A signal for subject.
    public private(set) lazy var signal = Signal(self)
    
    private lazy var observers = ThreadSafe(Storage<(Value) -> Void>())
    
    /// Map each value to a new value.
    ///
    /// - parameters:
    ///   - transform: A function that transform each value to a new value.
    ///
    /// - returns: A Signal that will send new values.
    @inline(__always)
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return signal.map(transform)
    }
    
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return subscribe(executor: executor, initialValue: nil, observer: observer)
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

extension Subject {
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///   - initialValue: Initial value to be received just on subscribed.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @inline(__always)
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
