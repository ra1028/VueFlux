import VueFlux

public struct Binder<Value> {
    let subscriptionScope = SubscriptionScope()

    private let binding: (Value) -> Void

    /// Construct the target.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - binding: A function to bind values.
    public init<Target: AnyObject>(target: Target, binding: @escaping (Target, Value) -> Void) {
        SubscriptionScope.ratained(by: target) += subscriptionScope
        
        self.binding = { [weak target] value in
            guard let target = target else { return }
            binding(target, value)
        }
    }
    
    /// Construct the target.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - keyPath: A function to bind values.
    public init<Target: AnyObject>(target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) {
        self.init(target: target) { target, value in
            target[keyPath: keyPath] = value
        }
    }
    
    /// Update target with given value.
    ///
    /// - Parameters:
    ///   - value: Value to update target.
    public func on(value: Value) {
        binding(value)
    }
}
