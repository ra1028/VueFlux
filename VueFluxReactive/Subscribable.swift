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
    /// Subscribe the observer function to be received the values until given scope object deinitialized.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deinitialize.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(scope object: AnyObject, observer: @escaping (Value) -> Void) -> Subscription {
        let subscription = subscribe(observer: observer)
        SubscriptionScope.owned(by: object) += subscription
        return subscription
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest value of `self` until binder target deinitialized.
    ///
    /// - Prameters:
    ///   - binder: A binder to be bound.
    ///
    /// - Returns: A subscription to unbind given binder.
    @discardableResult
    func bind(to binder: Binder<Value>) -> Subscription {
        return binder.bind(self)
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` until target deinitialized.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - binding: A function to bind values.
    ///
    /// - Returns: A subscription to unbind given target.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, binding: @escaping (Target, Value) -> Void) -> Subscription {
        return bind(to: .init(target: target, binding: binding))
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` until target deinitialized.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that bind values.
    ///
    /// - Returns: A subscription to unbind given target.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Subscription {
        return bind(to: .init(target: target, keyPath))
    }
}
