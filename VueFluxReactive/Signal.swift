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
    
    /// Observe the values to the given observer.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A disposable to unregister given observer.
    @discardableResult
    public func observe(_ observer: @escaping (Value) -> Void) -> Disposable {
        return producer(observer)
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
    ///
    /// - Returns: A disposable to unbind given binder.
    @discardableResult
    public func bind(to binder: Binder<Value>) -> Disposable {
        return binder.bind(signal: self)
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - binding: A function to bind values.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, binding: @escaping (Target, Value) -> Void) -> Disposable {
        return bind(to: .init(target: target, binding: binding))
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that to bind values.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value>) -> Disposable {
        return bind(to: target) { target, value in
            target[keyPath: keyPath] = value
        }
    }
    
    /// Binds the values to a target, updating the target's value to the latest value of `self` during scope of binder target.
    ///
    /// - Prameters:
    ///   - target: A binding target object.
    ///   - keyPath: The key path of the object that to bind values. Allows optional.
    ///
    /// - Returns: A disposable to unbind given target.
    @discardableResult
    public func bind<Target: AnyObject>(to target: Target, _ keyPath: ReferenceWritableKeyPath<Target, Value?>) -> Disposable {
        return bind(to: target) { target, value in
            target[keyPath: keyPath] = value as Value?
        }
    }
}
