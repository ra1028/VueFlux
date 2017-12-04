import VueFlux

/// A stream that can only receive values.
public final class Signal<Value>: Subscribable {
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    /// Initialize a new signal from subject.
    public convenience init(_ subject: Subject<Value>) {
        self.init(subject.subscribe(executor:observer:))
    }
    
    private init(_ subscribe: @escaping (Executor, @escaping (Value) -> Void) -> Subscription) {
        _subscribe = subscribe
    }
    
    /// Map each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that to transform each values to a new value.
    ///
    /// - Returns: A Signal that will send new values.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return .init { executor, observer in
            self.subscribe(executor: executor) { value in
                observer(transform(value))
            }
        }
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
        return _subscribe(executor, observer)
    }
}
