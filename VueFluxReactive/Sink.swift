import VueFlux

public struct Constant<Value> {
    public var value: Value {
        return variable.value
    }
    
    public var stream: Stream<Value> {
        return variable.stream
    }
    
    private let variable: Variable<Value>
    
    public init(_ value: Value) {
        self.variable = .init(value)
    }
    
    public init(variable: Variable<Value>) {
        self.variable = variable
    }
}

public final class Variable<Value> {
    public var value: Value {
        get {
            return core.value.value
        }
        set {
            core.modify { core in
                core.value = newValue
                core.observers.forEach { $0(newValue) }
            }
        }
    }
    
    public var stream: Stream<Value> {
        return .init { executor, observer in
            self.core.modify { core in
                let key = core.observers.append { value in
                    executor.execute { observer(value) }
                }
                
                let value = core.value
                executor.execute {
                    observer(value)
                }
                
                return AnySubscription { [weak self] in
                    self?.core.modify { core in
                        core.observers.remove(for: key)
                    }
                }
            }
        }
    }
    
    public var constant: Constant<Value> {
        return .init(variable: self)
    }
    
    private let core: ThreadSafe<(value: Value, observers: Storage<(Value) -> Void>)>
    
    public init(_ value: Value) {
        self.core = .init((value: value, observers: .init()))
    }
}

public struct Stream<Value>: Subscribable {
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    init(_ subscribe: @escaping (Executor, @escaping (Value) -> Void) -> Subscription) {
        _subscribe = subscribe
    }
    
    @discardableResult
    public func subscribe(executor: Executor = .mainThread, observer: @escaping (Value) -> Void) -> Subscription {
        return _subscribe(executor, observer)
    }
    
    public func map<T>(_ transform: @escaping (Value) -> T) -> Stream<T> {
        return .init { executor, observer in
            self.subscribe(executor: executor) { value in
                observer(transform(value))
            }
        }
    }
}

public final class Sink<Value> {
    public var stream: Stream<Value> {
        return .init { executor, observer in
            self.observers.modify { observers in
                let key = observers.append { value in
                    executor.execute { observer(value) }
                }
                
                return AnySubscription { [weak self] in
                    self?.observers.modify { observers in
                        observers.remove(for: key)
                    }
                }
            }
        }
    }
    
    private let observers = ThreadSafe(Storage<(Value) -> Void>())
    
    public func send(value: Value) {
        observers.synchronized { observers in
            observers.forEach { $0(value) }
        }
    }
}
