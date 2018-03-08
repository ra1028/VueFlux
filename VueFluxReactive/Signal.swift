import VueFlux

/// A stream that can be sending values over time.
public struct Signal<Value> {
    public typealias Producer = (@escaping (Value) -> Void) -> Disposable
    
    private let producer: (@escaping (Value) -> Void) -> Disposable
    
    /// Create new signal with a producer function.
    ///
    /// - Parameters:
    ///   - producer:  A function that to produce values.
    public init(_ producer: @escaping Producer) {
        self.producer = producer
    }
    
    /// Observe `self` for all values being sended.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A disposable to unregister given observer.
    @discardableResult
    public func observe(_ observer: @escaping (Value) -> Void) -> Disposable {
        let observerProcedure = CancelableProcedure<Value>(observer)
        let disposable = producer { value in
            observerProcedure.execute(with: value)
        }
        
        return AnyDisposable {
            observerProcedure.cancel()
            disposable.dispose()
        }
    }
    
    /// observe the values to the given observer during during scope of specified object.
    ///
    /// - Prameters:
    ///   - object: An object that will unregister given observer by being deinitialize.
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A disposable to unregister given observer.
    @discardableResult
    public func observe(duringScopeOf object: AnyObject, _ observer: @escaping (Value) -> Void) -> Disposable {
        let disposable = observe(observer)
        DisposableScope.associated(with: object) += disposable
        return disposable
    }
    
    /// Binds the values to a binder, updating the binder target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - binder: A binder to be bound.
    ///   - executor: A executor to forward events to binder on.
    ///
    /// - Returns: A disposable to unbind given binder.
    @discardableResult
    public func bind(to binder: Binder<Value>, on executor: Executor = .mainThread) -> Disposable {
        return binder.bind(signal: self, on: executor)
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - executor: A executor to forward events to binder on.
    ///   - binding: A function to bind values.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, on executor: Executor = .mainThread, binding: @escaping (Target, Value) -> Void) -> Disposable {
        return bind(to: .init(target: target, binding: binding), on: executor)
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that to bind values.
    ///   - executor: A executor to forward events to binder on.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>, on executor: Executor = .mainThread) -> Disposable {
        return bind(to: target, on: executor) { target, value in
            target[keyPath: keyPath] = value
        }
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that to bind values. Allows optional.
    ///   - executor: A executor to forward events to binder on.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value?>, on executor: Executor = .mainThread) -> Disposable {
        return bind(to: target, on: executor) { target, value in
            target[keyPath: keyPath] = value as Value?
        }
    }
}
