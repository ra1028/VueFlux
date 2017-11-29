import VueFlux

public final class Signal<Value>: Subscribable {
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    /// Initialize with subject.
    public convenience init(_ subject: Subject<Value>) {
        self.init(subject.subscribe(executor:observer:))
    }
    
    private init(_ subscribe: @escaping (Executor, @escaping (Value) -> Void) -> Subscription) {
        _subscribe = subscribe
    }
    
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return .init { executor, observer in
            self.subscribe(executor: executor) { value in
                observer(transform(value))
            }
        }
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
        return _subscribe(executor, observer)
    }
}
