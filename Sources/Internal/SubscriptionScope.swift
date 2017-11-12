/// A wrapper for automatically unsubscribe added subscriptions.
final class SubscriptionScope {
    private var subscriptions = ContiguousArray<Subscription>()
    
    deinit {
        for subscription in subscriptions {
            subscription.unsubscribe()
        }
    }
    
    /// Append a new subscription to a scope.
    ///
    /// - Parameters:
    ///   - scope: A scope to be add new subscription.
    ///   - subscription: A subscription to be add to scope.
    static func += (scope: SubscriptionScope, subscription: Subscription) {
        scope.subscriptions.append(subscription)
    }
}
