import ObjectiveC

private let subscriptionScopeKey = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))

extension Store {
    /// Subscribe the observer function to be receive on state change.
    /// Unsubscribed by deallocating the given object.
    ///
    /// - Prameters:
    ///   - scope: An object that will unsubscribe given observer function by being deallocate.
    ///   - executor: An executor to receive store and action on.
    ///   - observer: A function to be received a store and action on state change.
    ///
    /// - Returns: A subscription to unsubscribe given observer.
    @discardableResult
    public func subscribe(scope object: AnyObject, executor: Executor = .mainThread, observer: @escaping (Store, State.Action) -> Void) -> Subscription {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        let scope: SubscriptionScope = {
            if let scope = objc_getAssociatedObject(object, subscriptionScopeKey) as? SubscriptionScope {
                return scope
            }
            
            let scope = SubscriptionScope()
            objc_setAssociatedObject(object, subscriptionScopeKey, scope, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return scope
        }()
        
        let subscription = subscribe(executor: executor, observer: observer)
        scope += subscription
        return subscription
    }
}
