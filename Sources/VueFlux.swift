import Foundation

public class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State>()
    private var disposables = ContiguousArray<Dispatcher<State>.Disposable>()

    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    public lazy var actions: Actions<State> = .init(dispatcher: dispatcher)
    public lazy var expose: Expose<State> = .init(state: state)

//    public init(state: State, mutations: State.Mutations, scheduler: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
    public init(state: State, mutations: State.Mutations) {
        self.state = state
        self.mutations = mutations
        
        disposables.append(dispatcher.subscribe(store: self))
        disposables.append(Dispatcher<State>.shared.subscribe(store: self))
    }
    
    deinit {
        for disposable in disposables {
            disposable.dispose()
        }
    }

    fileprivate func dispatch(action: State.Action) {
        mutations.commit(action: action, state: state)
    }
}

public protocol Mutations {
    associatedtype State: VueFlux.State
    
    func commit(action: State.Action, state: State)
}

public protocol State: class {
    associatedtype Action
    associatedtype Mutations: VueFlux.Mutations where Mutations.State == Self
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

public struct Expose<State: VueFlux.State> {
    public let state: State
    
    fileprivate init(state: State) {
        self.state = state
    }
}

// MARK: - private

private final class Dispatcher<State: VueFlux.State> {
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let storage = Atomic(Storage())
    
    init() {}
    
    func dispatch(action: State.Action) {
        storage.synchronized { storage in
            storage.forEach { store in
                store.dispatch(action: action)
            }
        }
    }
    
    func subscribe(store: Store<State>) -> Disposable {//, on scheduler: ImmediateSchedulerType) -> Disposable {
        let key = storage.modify { $0.add(store: store) }
        return .init{ [weak self] in
            self?.storage.modify { $0.remove(for: key) }
        }
    }
}

private extension Dispatcher {
    struct Storage {
        private typealias Pair = (key: Key, store: Store<State>)
        
        private var buffer = ContiguousArray<Pair>()
        private var nextKey = Key.first
        
        mutating func add(store: Store<State>) -> Key {
            let key = nextKey
            nextKey = key.next
            buffer.append((key: key, store: store))
            return key
        }
        
        mutating func remove(for key: Key) {
            for index in self.buffer.startIndex..<self.buffer.endIndex where self.buffer[index].key == key {
                self.buffer.remove(at: index)
                break
            }
        }
        
        func forEach(_ body: (Store<State>) -> Void) {
            for pair in buffer {
                body(pair.store)
            }
        }
    }
}

private extension Dispatcher {
    final class Disposable {
        private let state = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private var action: (() -> Void)?
        
        var isDisposed: Bool {
            return state.pointee == 0
        }
        
        init(_ action: @escaping () -> Void) {
            self.action = action
            state.initialize(to: 0)
        }
        
        deinit {
            state.deinitialize()
            state.deallocate(capacity: 1)
        }
        
        func dispose() {
            if OSAtomicCompareAndSwap32Barrier(0, 1, state) {
                action?()
                action = nil
            }
        }
    }
}

private extension Dispatcher.Storage {
    struct Key: Equatable {
        private let rawValue: UInt64
        
        fileprivate static var first: Key {
            return .init(rawValue: 0)
        }
        
        fileprivate var next: Key {
            return .init(rawValue: rawValue &+ 1)
        }
        
        static func == (lhs: Key, rhs: Key) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
}

private final class DispatcherContext {
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
    private struct Identifier: Hashable {
        let hashValue: Int
        
        init<State: VueFlux.State>(for stateType: State.Type) {
            hashValue = String(reflecting: stateType).hashValue
        }
        
        static func ==(lhs: Identifier, rhs: Identifier) -> Bool {
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
    
    var value: Value {
        get { return modify { $0 } }
        set { modify { $0 = newValue } }
    }
    
    public init(_ value: Value) {
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
