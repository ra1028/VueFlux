import VueFlux

public struct Binder<Value> {
    let subscriptionScope: SubscriptionScope
    
    private let binding: (Value) -> Void

    /// Construct the target.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - binding: A function to bind values.
    public init<Target: AnyObject>(target: Target, binding: @escaping (Target, Value) -> Void) {
        self.subscriptionScope = .ratained(by: target)
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
    
    /// Binds given value to target.
    ///
    /// - Parameters:
    ///   - value: Value to bind to target.
    public func bind(value: Value) {
        binding(value)
    }
}
