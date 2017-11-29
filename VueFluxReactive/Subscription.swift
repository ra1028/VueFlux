/// Represents something that can be `unsubscribe`.
public protocol Subscription {
    /// A Bool value indicating whether unsubscribed.
    var isUnsubscribed: Bool { get }
    
    /// Unsubscribe if not already been unsubscribed.
    func unsubscribe()
}
