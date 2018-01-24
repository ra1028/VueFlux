/// A stream that can be sending values over time.
public struct Signal<Value> {
    public typealias Producer = (@escaping (Value) -> Void) -> Subscription
    
    private let producer: (@escaping (Value) -> Void) -> Subscription
    
    /// Create new signal with a producer function.
    ///
    /// - Parameters:
    ///   - producer:  A function that to produce values.
    public init(_ producer: @escaping Producer) {
        self.producer = producer
    }
    
    /// Observe the values to the given observer.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func observe(_ observer: @escaping (Value) -> Void) -> Subscription {
        return producer(observer)
    }
    
    /// observe the values to the given observer during during scope of specified object.
    ///
    /// - Prameters:
    ///   - object: An object that will unsubscribe given observer by being deinitialize.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    func observe(duringScopeOf object: AnyObject, _ observer: @escaping (Value) -> Void) -> Subscription {
        let subscription = observe(observer)
        SubscriptionScope.associated(with: object) += subscription
        return subscription
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - binder: A binder to be bound.
    ///
    /// - Returns: A subscription to unbind given binder.
    @discardableResult
    func bind(to binder: Binder<Value>) -> Subscription {
        return binder.bind(signal: self)
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
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
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
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
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
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
