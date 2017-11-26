import VueFlux

public struct Binder<Value> {
    let subscriptionScope: SubscriptionScope
    
    private let binding: (Value) -> Void

    /// Construct the target.
    ///
    /// - Parameters:
    ///   - executor: An executor to bind values on.
    ///   - target: Target object.
    ///   - binding: A function to bind values.
    public init<Target: AnyObject>(executor: Executor = .mainThread, target: Target, binding: @escaping (Target, Value) -> Void) {
        self.subscriptionScope = .ratained(by: target)
        self.binding = { [weak target] value in
            executor.execute {
                guard let target = target else { return }
                binding(target, value)
            }
        }
    }
    
    /// Construct the target.
    ///
    /// - Parameters:
    ///   - executor: An executor to bind values on.
    ///   - target: Target object.
    ///   - keyPath: A function to bind values.
    public init<Target: AnyObject>(executor: Executor = .mainThread, target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) {
        self.init(executor: executor, target: target) { target, value in
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
