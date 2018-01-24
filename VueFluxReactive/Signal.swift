/// A stream that can be sending values over time.
public struct Signal<Value> {
    public typealias Producer = (@escaping (Value) -> Void) -> Subscription
    
    private let producer: (@escaping (Value) -> Void) -> Subscription
    
    /// Create a signal with subscribed function.
    ///
    /// - Parameters:
    ///   - producer: A function of behavior when subscribed.
    public init(_ producer: @escaping Producer) {
        self.producer = producer
    }
    
    /// Subscribe the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(observer: @escaping (Value) -> Void) -> Subscription {
        return producer(observer)
    }
    
    /// Subscribe the observer function to be received the values during scope of given object deinitialized.
    ///
    /// - Prameters:
    ///   - object: An object that will unsubscribe given observer by being deinitialize.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func subscribe(duringScopeOf object: AnyObject, observer: @escaping (Value) -> Void) -> Subscription {
        let subscription = subscribe(observer: observer)
        SubscriptionScope.associated(with: object) += subscription
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
        return binder.bind(signal: self)
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
    ///   - keyPath: The key path of the object that to bind values.
    ///
    /// - Returns: A subscription to unbind given target.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Subscription {
        return bind(to: target) { target, value in
            target[keyPath: keyPath] = value
        }
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` until target deinitialized.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that to bind values. Allows optional.
    ///
    /// - Returns: A subscription to unbind given target.
    @discardableResult
    func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value?>) -> Subscription {
        return bind(to: target) { target, value in
            target[keyPath: keyPath] = value as Value?
        }
    }
}
