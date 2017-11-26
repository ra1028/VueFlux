/// A wrapper for automatically unsubscribe added subscriptions.
public final class SubscriptionScope {
    private var subscriptions = ContiguousArray<Subscription>()
    
    deinit {
        for subscription in subscriptions {
            subscription.unsubscribe()
        }
    }
    
    /// Append a new subscription to a scope.
    ///
    /// - Parameters:
    ///   - subscription: A subscription to be add to scope.
    public func append(subscription: Subscription) {
        subscriptions.append(subscription)
    }
    
    /// An operator for append a new subscription to a scope.
    ///
    /// - Parameters:
    ///   - scope: A scope to be add new subscription.
    ///   - subscription: A subscription to be add to scope.
    public static func += (scope: SubscriptionScope, subscription: Subscription) {
        scope.append(subscription: subscription)
    }
}
