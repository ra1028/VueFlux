import Foundation

public class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State>()
    private var subscribedDispatchers = ContiguousArray<(key: Dispatcher<State>.Key, dispatcher: Dispatcher<State>)>()
    
    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    public lazy var actions: Actions<State> = .init(dispatcher: dispatcher)
    public lazy var computed: Computed<State> = .init(state: state)
    
    public init(state: State, mutations: State.Mutations, executer: Executer) {
        self.state = state
        self.mutations = mutations
        
        @inline(__always)
        func subscribe(to dispatcher: Dispatcher<State>) {
            let key = dispatcher.subscribe(store: self, executer: executer)
            subscribedDispatchers.append((key: key, dispatcher: dispatcher))
        }
        
        subscribe(to: dispatcher)
        subscribe(to: Dispatcher<State>.shared)
    }
    
    deinit {
        for (key, dispatcher) in subscribedDispatchers {
            dispatcher.unsubscribe(for: key)
        }
    }
    
    fileprivate func dispatch(action: State.Action) {
        mutations.commit(action: action, state: state)
    }
}

public protocol State: class {
    associatedtype Action
    associatedtype Mutations: VueFlux.Mutations where Mutations.State == Self
}

public protocol Mutations {
    associatedtype State: VueFlux.State
    
    func commit(action: State.Action, state: State)
}

public struct Actions<State: VueFlux.State> {
    private let dispatcher: Dispatcher<State>
    
    fileprivate init(dispatcher: Dispatcher<State>) {
        self.dispatcher = dispatcher
    }
    
    public func dispatch(action: State.Action) {
        dispatcher.dispatch(action: action)
    }
}

public struct Computed<State: VueFlux.State> {
    public let state: State
    
    fileprivate init(state: State) {
        self.state = state
    }
}

public struct Executer {
    public static var immediate: Executer {
        return .init { execute in
            execute()
        }
    }
    
    public static var mainThread: Executer {
        let innerExecuter = MainThreadInnerExecuter()
        return .init(innerExecuter.execute(_:))
    }
    
    public static func queue(_ dispatchQueue: DispatchQueue) -> Executer {
        return .init { execute in
            dispatchQueue.async(execute: execute)
        }
    }
    
    private let executer: (@escaping () -> Void) -> Void
    
    private init(_ executer: @escaping (@escaping () -> Void) -> Void) {
        self.executer = executer
    }
    
    public func execute(_ body: @escaping () -> Void) {
        executer(body)
    }
}

// MARK: - Private

private extension Executer {
    final class MainThreadInnerExecuter {
        private let executingCount: UnsafeMutablePointer<Int32> = {
            let memory = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            memory.initialize(to: 0)
            return memory
        }()
        
        deinit {
            executingCount.deinitialize()
            executingCount.deallocate(capacity: 1)
        }
        
        func execute(_ action: @escaping () -> Void) {
            let count = OSAtomicIncrement32(executingCount)
            
            if Thread.isMainThread && count == 1 {
                action()
                OSAtomicDecrement32(executingCount)
            } else {
                DispatchQueue.main.async {
                    action()
                    OSAtomicDecrement32(self.executingCount)
                }
            }
        }
    }
}

private final class Dispatcher<State: VueFlux.State> {
    private typealias Subscription = (key: Key, observer: (State.Action) -> Void)
    private typealias Buffer = (nextKey: Key, subscriptions: ContiguousArray<Subscription>)
    
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let buffer = Atomic<Buffer>((nextKey: Key.first, subscriptions: []))
    
    init() {}
    
    func dispatch(action: State.Action) {
        buffer.synchronized { buffer in
            for entry in buffer.subscriptions {
                entry.observer(action)
            }
        }
    }
    
    func subscribe(store: Store<State>, executer: Executer) -> Key {
        return buffer.modify { buffer in
            let key = buffer.nextKey
            buffer.nextKey = key.next
            
            let observer: (State.Action) -> Void = { [weak store] action in
                executer.execute { store?.dispatch(action: action) }
            }
            
            buffer.subscriptions.append((key: key, observer: observer))
            return key
        }
    }
    
    func unsubscribe(for key: Key) {
        buffer.modify { buffer in
            for index in buffer.subscriptions.startIndex..<buffer.subscriptions.endIndex where buffer.subscriptions[index].key == key {
                buffer.subscriptions.remove(at: index)
                break
            }
        }
    }
}

private extension Dispatcher {
    struct Key: Equatable {
        private let value: UInt64
        
        static var first: Key {
            return .init(value: 0)
        }
        
        var next: Key {
            return .init(value: value &+ 1)
        }
        
        private init(value: UInt64) {
            self.value = value
        }
        
        static func == (lhs: Key, rhs: Key) -> Bool {
            return lhs.value == rhs.value
        }
    }
}

private struct DispatcherContext {
    static let shared = DispatcherContext()
    
    private var dispatchers = Atomic([Identifier: Any]())
    
    private init() {}
    
    func dispatcher<State: VueFlux.State>(for stateType: State.Type) -> Dispatcher<State> {
        return dispatchers.modify { dispatchers in
            let identifier = Identifier(for: stateType)
            if let dispatcher = dispatchers[identifier] as? Dispatcher<State> {
                return dispatcher
            }
            
            let dispatcher = Dispatcher<State>()
            dispatchers[identifier] = dispatcher
            return dispatcher
        }
    }
}

private extension DispatcherContext {
    struct Identifier: Hashable {
        let hashValue: Int
        
        init<State: VueFlux.State>(for stateType: State.Type) {
            hashValue = String(reflecting: stateType).hashValue
        }
        
        static func == (lhs: Identifier, rhs: Identifier) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
}

private final class Atomic<Value> {
    private var innerValue: Value
    private let lock: NSLocking = {
        if #available(iOS 10.0, *) {
            return OSUnfairLock()
        } else {
            return PosixThreadMutex()
        }
    }()
    
    init(_ value: Value) {
        innerValue = value
    }
    
    @discardableResult
    func synchronized<Result>(_ action: (Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try action(innerValue)
    }
    
    @discardableResult
    func modify<Result>(_ action: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try action(&innerValue)
    }
}

extension Atomic {
    @available(iOS 10.0, *)
    private final class OSUnfairLock: NSLocking {
        private let _lock = os_unfair_lock_t.allocate(capacity: 1)
        
        init() {
            _lock.initialize(to: os_unfair_lock())
        }
        
        deinit {
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        func lock() {
            os_unfair_lock_lock(_lock)
        }
        
        func unlock() {
            os_unfair_lock_unlock(_lock)
        }
    }
    
    private final class PosixThreadMutex: NSLocking {
        private let _lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        
        init() {
            _lock.initialize(to: pthread_mutex_t())
            
            let result = pthread_mutex_init(_lock, nil)
            assert(result == 0)
        }
        
        deinit {
            let result = pthread_mutex_destroy(_lock)
            assert(result == 0)
            
            _lock.deinitialize()
            _lock.deallocate(capacity: 1)
        }
        
        func lock() {
            let result = pthread_mutex_lock(_lock)
            assert(result == 0)
        }
        
        func unlock() {
            let result = pthread_mutex_unlock(_lock)
            assert(result == 0)
        }
    }
}
