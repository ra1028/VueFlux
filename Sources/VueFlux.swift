import Foundation

open class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State>()
    private var subscribedDispatchers = ContiguousArray<(key: Dispatcher<State>.Key, dispatcher: Dispatcher<State>)>()
    
    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    public lazy var actions: Actions<State> = .init(dispatcher: dispatcher)
    public lazy var computed: Computed<State> = .init(state: state)
    
    public init(state: State, mutations: State.Mutations, executor: Executor) {
        self.state = state
        self.mutations = mutations
        
        @inline(__always)
        func subscribe(to dispatcher: Dispatcher<State>) {
            let key = dispatcher.subscribe(executor: executor) { [weak self] action in
                self?.dispatch(action: action)
            }
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

public struct Executor {
    public static var immediate: Executor {
        return .init { execute in execute() }
    }
    
    public static var mainThread: Executor {
        let innerExecutor = MainThreadInnerExecutor()
        return .init(innerExecutor.execute(_:))
    }
    
    public static func queue(_ dispatchQueue: DispatchQueue) -> Executor {
        return .init { execute in dispatchQueue.async(execute: execute) }
    }
    
    private let executor: (@escaping () -> Void) -> Void
    
    private init(_ executor: @escaping (@escaping () -> Void) -> Void) {
        self.executor = executor
    }
    
    public func execute(_ body: @escaping () -> Void) {
        executor(body)
    }
}

private extension Executor {
    final class MainThreadInnerExecutor {
        private let executingCount = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        init() {
            executingCount.initialize(to: 0)
        }
        
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
