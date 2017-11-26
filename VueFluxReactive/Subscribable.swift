import VueFlux

/// Represents an class with have subscribe function.
public protocol Subscribable: class {
    associatedtype Value
    
    /// Subscribe the observer function to be received the value.
    ///
    /// - Prameters:
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    func subscribe(executor: Executor, observer: @escaping (Value) -> Void) -> Subscription
}
