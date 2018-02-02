import VueFlux

public struct Binder<Value> {
    private let addDisposable: (Disposable) -> Void
    private let binding: (Value) -> Void

    /// Create the Binder with target object and binding function.
    ///
    /// - Parameters:
    ///   - target: Target object.
    ///   - binding: A function to bind values.
    public init<Target: AnyObject>(target: Target, binding: @escaping (Target, Value) -> Void) {
        self.addDisposable = { [weak target] disposable in
            guard let target = target else { return disposable.dispose() }
            DisposableScope.associated(with: target).add(disposable: disposable)
        }
        
        self.binding = { [weak target] value in
            guard let target = target else { return }
            binding(target, value)
        }
    }
    
    /// Binds the values, updating the target's value to the latest value of signal until target deinitialized.
    ///
    /// - Parameters:
    ///   - signal: A signal that updating the target's value to its latest value.
    ///   - executor: A executor to forward events to binding on.
    ///
    /// - Returns: A disposable to unbind from signal.
    public func bind(signal: Signal<Value>, on executor: Executor) -> Disposable {
        let disposable = signal.observe(on: executor).observe(binding)
        addDisposable(disposable)
        return disposable
    }
}
