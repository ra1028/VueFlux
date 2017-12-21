import VueFlux

/// Represents an object wich have subscribe function.
public protocol Subscribable {
    associatedtype Value
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(observer: @escaping (Value) -> Void) -> Subscription
}

public extension Subscribable {
    /// Subscribe the observer function to be received the values.
    /// Unsubscribed by deallocating the given scope object.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deallocate.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(scope object: AnyObject, observer: @escaping (Value) -> Void) -> Subscription {
        return subscribe(subscriptionScope: .owned(by: object), observer: observer)
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest.
    /// Unsubscribed by deallocating the binder's target.
    ///
    /// - Prameters:
    ///   - binder: A binder to be bound.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind(to binder: Binder<Value>) -> Subscription {
        return subscribe(subscriptionScope: binder.subscriptionScope, observer: binder.on(value:))
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest.
    /// Unsubscribed by deallocating the target object.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - binding: A function to bind values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, binding: @escaping (Target, Value) -> Void) -> Subscription {
        return bind(to: .init(target: target, binding: binding))
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest.
    /// Unsubscribed by deallocating the target object.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that bind values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Subscription {
        return bind(to: .init(target: target, keyPath))
    }
}

private extension Subscribable {
    /// Subscribe the observer function to be received the values.
    /// Unsubscribed by given SubscriptionScope.
    ///
    /// - Prameters:
    ///   - subscriptionScope: A SubscriptionScope that to be unsubscribe.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @inline(__always)
    func subscribe(subscriptionScope: SubscriptionScope, observer: @escaping (Value) -> Void) -> Subscription {
        let subscription = subscribe(observer: observer)
        subscriptionScope += subscription
        return subscription
    }
}
