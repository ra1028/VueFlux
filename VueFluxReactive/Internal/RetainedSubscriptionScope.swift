import ObjectiveC

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
