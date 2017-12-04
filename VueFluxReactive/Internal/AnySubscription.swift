import VueFlux

/// An Unsubscribe function wrapper.
struct AnySubscription: Subscription {
    private enum State {
        case subscribing(unsubscribe: () -> Void)
        case unsubscribed
    }
    
    private let state: ThreadSafe<State>
    
    /// A Bool value indicating whether unsubscribed.
    var isUnsubscribed: Bool {
        guard case .unsubscribed = state.value else { return false }
        return true
    }
    
    /// Create with unsubscribe function.
    init(unsubscribe: @escaping (() -> Void)) {
        state = .init(.subscribing(unsubscribe: unsubscribe))
    }
    
    /// Unsubscribe if not already been unsubscribed.
    func unsubscribe() {
        guard case let .subscribing(unsubscribe) = state.swap(.unsubscribed) else { return }
        unsubscribe()
    }
}
