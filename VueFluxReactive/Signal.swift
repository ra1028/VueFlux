import VueFlux

public final class Signal<Value>: Subscribable {
    private let subject: Subject<Value>
    
    /// Initialize with subject.
    public init(_ subject: Subject<Value>) {
        self.subject = subject
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
        return subject.subscribe(executor: executor, observer: observer)
    }
}
