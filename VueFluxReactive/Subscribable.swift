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
    @discardableResult
    func subscribe(executor: Executor, observer: @escaping (Value) -> Void) -> Subscription
}

public extension Subscribable {
    /// Subscribe the observer function to be received the value.
    /// Unsubscribed by deallocating the given scope object.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deallocate.
    ///   - executor: An executor to receive value on.
    ///   - observer: A function to be received the value.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(scope object: AnyObject, executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        let subscriptionScope = SubscriptionScope.ratained(by: object)
        return subscribe(subscriptionScope: subscriptionScope, executor: executor, observer: observer)
    }
    
    /// Binds a values to a binder, updating the binder target's value to the latest value.
    /// Unsubscribed by deallocating the given scope object.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deallocate.
    ///   - binder: A binder to be bound.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind(scope: AnyObject, to binder: Binder<Value>) -> Subscription {
        return subscribe(scope: scope, executor: .immediate, observer: binder.bind(value:))
    }
    
    /// Binds a values to a binder, updating the binder target's value to the latest value.
    /// Unsubscribed by deallocating the binder's target.
    ///
    /// - Prameters:
    ///   - binder: A binder to be bound.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind(to binder: Binder<Value>) -> Subscription {
        return subscribe(subscriptionScope: binder.subscriptionScope, executor: .immediate, observer: binder.bind(value:))
    }

    /// Binds a values to a target, updating the target's value to the latest value.
    /// Unsubscribed by deallocating the given scope object.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deallocate.
    ///   - executor: An executor to bind on.
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that bind values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind<Target: AnyObject>(scope: AnyObject, executor: Executor = .mainThread, to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Subscription {
        return bind(scope: scope, to: .init(executor: executor, target: target, keyPath))
    }
    
    /// Binds a values to a target, updating the target's value to the latest value.
    /// Unsubscribed by deallocating the target object.
    ///
    /// - Prameters:
    ///   - executor: An executor to bind on.
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that bind values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func bind<Target: AnyObject>(executor: Executor = .mainThread, to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Subscription {
        return bind(scope: target, to: .init(executor: executor, target: target, keyPath))
    }
}

private extension Subscribable {
    func subscribe(subscriptionScope: SubscriptionScope, executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        let subscription = subscribe(executor: executor, observer: observer)
        subscriptionScope += subscription
        return subscription
    }
}
