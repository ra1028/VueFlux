import VueFlux

public struct Binder<Value> {
    private let addSubscription: (Subscription) -> Void
    private let binding: (Value) -> Void

    /// Create the Binder with target object and binding function.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - binding: A function to bind values.
    public init<Target: AnyObject>(target: Target, binding: @escaping (Target, Value) -> Void) {
        self.addSubscription = { [weak target] subscription in
            guard let target = target else { return subscription.unsubscribe() }
            SubscriptionScope.associated(with: target).add(subscription: subscription)
        }
        
        self.binding = { [weak target] value in
            guard let target = target else { return }
            binding(target, value)
        }
    }
    
    /// Create with target object and keyPath for binding.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - keyPath: A function to bind values.
    public init<Target: AnyObject>(target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) {
        self.init(target: target) { target, value in
            target[keyPath: keyPath] = value
        }
    }
    
    /// Binds the values, updating the target's value to the latest value of source until target deinitialized.
    ///
    /// - Parameters:
    ///   - source: A subscribable source that updating the target's value to its latest value.
    ///
    /// - Returns: A subscription to unbind from source.
    public func bind<Source: Subscribable>(_ source: Source) -> Subscription where Source.Value == Value {
        let subscription = source.subscribe(observer: binding)
        addSubscription(subscription)
        return subscription
    }
}
