import ObjectiveC

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

private let subscriptionScopeKey = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))

extension SubscriptionScope {
    static func ratained(by object: AnyObject) -> SubscriptionScope {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        if let subscriptionScope = objc_getAssociatedObject(object, subscriptionScopeKey) as? SubscriptionScope {
            return subscriptionScope
        }
        
        let subscriptionScope = SubscriptionScope()
        objc_setAssociatedObject(object, subscriptionScopeKey, subscriptionScope, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return subscriptionScope
    }
}
