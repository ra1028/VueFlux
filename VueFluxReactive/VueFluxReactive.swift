import VueFlux

public struct Sink<Value> {
    public var stream: Stream<Value> {
        return .init(subject.subscribe(executor:observer:))
    }
    
    private let subject = Subject<Value>()
    
    public func send(value: Value) {
        subject.send(value: value)
    }
}

public struct Stream<Value>: Subscribable {
    private let _subscribe: (Executor, @escaping (Value) -> Void) -> Subscription
    
    fileprivate init(_ subscribe: @escaping (Executor, @escaping (Value) -> Void) -> Subscription) {
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

public struct Variable<Value> {
    public var constant: Constant<Value> {
        return .init(variable: self)
    }
    
    public var stream: Stream<Value> {
        return .init { executor, observer in
            self._value.synchronized { value in
                self.subject.subscribe(executor: executor, initialValue: value, observer: observer)
            }
        }
    }
    
    public var value: Value {
        get {
            return _value.value
        }
        set {
            _value.modify { value in
                value = newValue
                subject.send(value: newValue)
            }
        }
    }
    
    private let subject = Subject<Value>()
    private var _value: ThreadSafe<Value>
    
    public init(_ value: Value) {
        _value = .init(value)
    }
}

public struct Constant<Value> {
    public var stream: Stream<Value> {
        return variable.stream
    }
    
    public var value: Value {
        return variable.value
    }
    
    private let variable: Variable<Value>
    
    public init(_ value: Value) {
        self.variable = .init(value)
    }
    
    public init(variable: Variable<Value>) {
        self.variable = variable
    }
}
