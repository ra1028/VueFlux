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
    
    /// Binds the values, updating the target's value to the latest value of signal until target deinitialized.
    ///
    /// - Parameters:
    ///   - signal: A signal that updating the target's value to its latest value.
    ///
    /// - Returns: A subscription to unbind from signal.
    public func bind(signal: Signal<Value>) -> Subscription {
        let subscription = signal.subscribe(observer: binding)
        addSubscription(subscription)
        return subscription
    }
}
