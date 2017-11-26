import Foundation

/// Manages a `State` and commits the action received via Dispatcher to Mutations.
open class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State>()
    private let sharedDispatcher = Dispatcher<State>.shared
    private var sharedDispatcherKey: Dispatcher<State>.Observers.Key?
    
    /// An actions proxy via shared dispatcher.
    /// Action is dispatched to all stores which have same generic type of State.
    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    /// A proxy for actions dispatch via dispatcher retained by `self`.
    public lazy var actions: Actions<State> = .init(dispatcher: dispatcher)
    
    /// A proxy for computed properties to be published of `State`.
    public lazy var computed: Computed<State> = .init(state: state)
    
    /// Initialize and subscribe to Dispachers.
    ///
    /// - Parameters:
    ///   - state: A state to be managed in `self`.
    ///   - mutations: A mutations for mutate the state.
    ///   - executor: An executor to dispatch actions on.
    public init(state: State, mutations: State.Mutations, executor: Executor) {
        self.state = state
        self.mutations = mutations
        
        let dispatch: ((State.Action) -> Void) = { [weak self] action in
            self?.commit(action: action)
        }
        
        dispatcher.subscribe(executor: executor, dispatch: dispatch)
        sharedDispatcherKey = sharedDispatcher.subscribe(executor: executor, dispatch: dispatch)
    }
    
    deinit {
        if let key = sharedDispatcherKey {
            sharedDispatcher.unsubscribe(for: key)
        }
    }
    
    /// Commit action to mutations.
    ///
    /// - Parameters:
    ///   - action: An action to mutate state.
    fileprivate func commit(action: State.Action) {
        mutations.commit(action: action, state: state)
    }
}

/// Represents a state can be managed by Store.
public protocol State: class {
    associatedtype Action
    associatedtype Mutations: VueFlux.Mutations where Mutations.State == Self
}

/// Represents a proxy for function to mutate a `State`.
public protocol Mutations {
    associatedtype State: VueFlux.State
    
    /// Mutate a state by given action.
    /// The only way to actually mutate state in a Store.
    func commit(action: State.Action, state: State)
}

/// A proxy of functions for dispatching actions.
public struct Actions<State: VueFlux.State> {
    private let dispatcher: Dispatcher<State>
    
    /// Construct the proxy.
    ///
    /// - Parameters:
    ///   - dispather: A dispatcher to dispatch the actions to.
    fileprivate init(dispatcher: Dispatcher<State>) {
        self.dispatcher = dispatcher
    }
    
    /// Dispatch given action to dispatcher.
    ///
    /// - Parameters:
    ///   - action: An action to be dispatch.
    public func dispatch(action: State.Action) {
        dispatcher.dispatch(action: action)
    }
}

/// A proxy of properties to be published of `State`.
public struct Computed<State: VueFlux.State> {
    public let state: State
    
    /// Construct the proxy.
    ///
    /// - Parameters:
    ///   - state: A state to be proxied.
    fileprivate init(state: State) {
        self.state = state
    }
}

/// Executes arbitrary function by given behavior.
public struct Executor {
    /// Executes function immediately and synchronously.
    public static var immediate: Executor {
        return .init { function in function() }
    }
    
    /// Exxecutes function on main-thread.
    /// If called execute on main-thread, function is not enqueue and execute immediately.
    public static var mainThread: Executor {
        let innerExecutor = MainThreadInnerExecutor()
        return .init(innerExecutor.execute(_:))
    }
    
    /// All the executions are enqueued to given qeueue.
    public static func queue(_ dispatchQueue: DispatchQueue) -> Executor {
        return .init { function in dispatchQueue.async(execute: function) }
    }
    
    private let executor: (@escaping () -> Void) -> Void
    
    /// Construct with executor function.
    ///
    /// - Parameters:
    ///   - executor: A function to that executes other function.
    public init(_ executor: @escaping (@escaping () -> Void) -> Void) {
        self.executor = executor
    }
    
    /// Execute an arbitrary function.
    ///
    /// - Parameters:
    ///   - function: A function to be execute.
    public func execute(_ function: @escaping () -> Void) {
        executor(function)
    }
}

private extension Executor {
    /// Inner executor that serial execute on main thread.
    final class MainThreadInnerExecutor {
        private let executingCount = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        /// Initialize a inner executor.
        init() {
            executingCount.initialize(to: 0)
        }
        
        deinit {
            executingCount.deinitialize()
            executingCount.deallocate(capacity: 1)
        }
        
        /// Serial execute a function on main thread.
        ///
        /// - Parameters:
        ///   - function: A function to be execute.
        func execute(_ function: @escaping () -> Void) {
            let count = OSAtomicIncrement32(executingCount)
            
            if Thread.isMainThread && count == 1 {
                function()
                OSAtomicDecrement32(executingCount)
            } else {
                DispatchQueue.main.async {
                    function()
                    OSAtomicDecrement32(self.executingCount)
                }
            }
        }
    }
}
