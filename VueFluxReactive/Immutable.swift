import VueFlux

public final class Immutable<Value>: Subscribable {
    /// A signal that will send the value changes.
    public var signal: Signal<Value> {
        return mutable.signal
    }
    
    private let mutable: Mutable<Value>
    
    /// Initialize with mutable.
    public init(_ mutable: Mutable<Value>) {
        self.mutable = mutable
    }
    
    /// The current value.
    public var value: Value {
        return mutable.value
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
        return mutable.subscribe(executor: executor, observer: observer)
    }
}
