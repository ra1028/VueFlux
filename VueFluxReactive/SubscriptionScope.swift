import VueFlux

/// A wrapper for automatically unsubscribe added subscriptions.
public final class SubscriptionScope: Subscription {
    private enum State {
        case active
        case unsubscribed
    }
    
    /// A Bool value indicating whether unsubscribed.
    public var isUnsubscribed: Bool {
        guard case .unsubscribed = state.value else { return false }
        return true
    }
    
    private let state = ThreadSafe<State>(.active)
    private let subscriptions: ThreadSafe<ContiguousArray<Subscription>>
    
    deinit {
        unsubscribe()
    }
    
    /// Initialize with the given subscriptions.
    ///
    /// - Parameters:
    ///   - subscriptions: Sequence of something conformed to `Subscription`.
    public init<Sequence: Swift.Sequence>(_ subscriptions: Sequence) where Sequence.Element == Subscription {
        self.subscriptions = .init(.init(subscriptions))
    }
    
    /// Initialize the empty `SubscriptionScope`.
    public convenience init() {
        self.init([])
    }
    
    /// Add a new subscription to a scope.
    ///
    /// - Parameters:
    ///   - subscription: A subscription to be add to scope.
    public func add(subscription: Subscription) {
        guard !subscription.isUnsubscribed else { return subscription.unsubscribe() }
        
        subscriptions.modify { subscriptions in
            subscriptions.append(subscription)
        }
    }
    
    /// Unsubscribe all subscriptions if not already been unsubscribed.
    public func unsubscribe() {
        guard case .active = state.swap(.unsubscribed) else { return }
        
        for subscription in subscriptions.swap([]) {
            subscription.unsubscribe()
        }
    }
    
    /// An operator for append a new subscription to a scope.
    ///
    /// - Parameters:
    ///   - subscriptionScope: A scope to be add new subscription.
    ///   - subscription: A subscription to be add to scope.
    public static func += (subscriptionScope: SubscriptionScope, subscription: Subscription) {
        subscriptionScope.add(subscription: subscription)
    }
}
