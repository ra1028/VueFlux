import VueFlux

public final class Subject<Value>: Subscribable {
    /// A signal for subject
    public private(set) lazy var signal = Signal(self)
    
    private var unsafeObservers = Storage<(Value) -> Void>()
    private lazy var observers = ThreadSafe(unsafeObservers)
    
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return subscribe(executor: executor, observer: observer, inserted: nil)
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
    /// Subscribe the observer function non-thread safely.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void, inserted: (() -> Void)?) -> Subscription {
        return observers.modify { observers in
            let key = observers.append { value in
                executor.execute { observer(value) }
            }
            inserted?()
            
            return .init { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
}
