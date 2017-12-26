import ObjectiveC

extension SubscriptionScope {
    /// Take a SubscriptionScope associated with given object.
    ///
    /// - Prameters:
    ///   - object: An object that associates with SubscriptionScope.
    ///
    /// - Returns: A SubscriptionScope associated with given object.
    static func associated(with object: AnyObject) -> SubscriptionScope {
        struct Keys {
            static let subscriptionScope = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
        }
        
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        if let subscriptionScope = objc_getAssociatedObject(object, Keys.subscriptionScope) as? SubscriptionScope {
            return subscriptionScope
        }
        
        let subscriptionScope = SubscriptionScope()
        objc_setAssociatedObject(object, Keys.subscriptionScope, subscriptionScope, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return subscriptionScope
    }
}
