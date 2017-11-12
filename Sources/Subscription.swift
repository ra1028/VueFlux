/// An Unsubscribe function wrapper.
public struct Subscription {
    private enum State {
        case subscribing(unsubscribe: () -> Void)
        case unsubscribed
    }
    
    private let state: Atomic<State>
    
    /// A Bool value indicating whether a subscription is unsubscribed.
    public var isUnsubscribed: Bool {
        guard case .unsubscribed = state.value else { return false }
        return true
    }
    
    /// Construct with unsubscribe function.
    init(unsubscribe: @escaping (() -> Void)) {
        state = .init(.subscribing(unsubscribe: unsubscribe))
    }
    
    /// Execute unsubscribe function if not already been unsubscribed.
    public func unsubscribe() {
        guard case .subscribing(let unsubscribe) = state.swap(.unsubscribed) else { return }
        unsubscribe()
    }
}
