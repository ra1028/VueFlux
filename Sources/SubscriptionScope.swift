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

extension Subscription {
    /// Execute unsubscribe function of `self` at time of deallocation of given object.
    ///
    /// - Parameters:
    ///   - object: An object that execute unsubscribe function of `self` at dealocation on.
    public func unsubscribed(byScopeOf object: AnyObject) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let scope: SubscriptionScope = {
            if let scope = objc_getAssociatedObject(object, subscriptionScopeKey) as? SubscriptionScope {
                return scope
            }
            
            let scope = SubscriptionScope()
            objc_setAssociatedObject(object, subscriptionScopeKey, scope, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return scope
        }()
        
        scope.append(subscription: self)
    }
}
