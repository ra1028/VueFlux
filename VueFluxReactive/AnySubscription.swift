import VueFlux

/// An Unsubscribe function wrapper.
public struct AnySubscription: Subscription {
    private enum State {
        case subscribing(unsubscribe: () -> Void)
        case unsubscribed
    }
    
    private let state: ThreadSafe<State>
    
    /// A Bool value indicating whether unsubscribed.
    public var isUnsubscribed: Bool {
        guard case .unsubscribed = state.value else { return false }
        return true
    }
    
    /// Create with unsubscribe function.
    public init(unsubscribe: @escaping (() -> Void)) {
        state = .init(.subscribing(unsubscribe: unsubscribe))
    }
    
    /// Unsubscribe if not already been unsubscribed.
    public func unsubscribe() {
        guard case let .subscribing(unsubscribe) = state.swap(.unsubscribed) else { return }
        unsubscribe()
    }
}
