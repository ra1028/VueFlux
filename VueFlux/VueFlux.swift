/// Manages a State and commits the action received via dispatcher to mutations.
open class Store<State, Action> {
    private let dispatcher = Dispatcher<State, Action>()
    private let sharedDispatcher = Dispatcher<State, Action>.shared
    
    private let commitProcedure: CancelableProcedure<Action>
    private let dispatcherKey: Dispatcher<State, Action>.Observers.Key
    private let sharedDispatcherKey: Dispatcher<State, Action>.Observers.Key
    
    /// An action proxy that dispatches actions via shared dispatcher.
    /// Action is dispatched to all stores which have same generic type of State.
    public static var actions: Actions<State, Action> {
        return .init(dispatcher: Dispatcher<State, Action>.shared)
    }
    
    /// A action proxy that dispatches actions via dispatcher retained by `self`.
    public let actions: Actions<State, Action>
    
    /// A proxy for computed properties to be published of State.
    public let computed: Computed<State>
    
    /// Initialize a new store.
    ///
    /// - Parameters:
    ///   - state: A state to be managed in `self`.
    ///   - mutations: A mutations for mutates the state.
    ///   - executor: An executor to dispatch actions on.
    public init<M: Mutations>(state: State, mutations: M, executor: Executor) where M.State == State, M.Action == Action {
        let commitProcedure = CancelableProcedure<Action> { action in
            mutations.commit(action: action, state: state)
        }
        
        let commit: (Action) -> Void = { action in
            executor.execute { commitProcedure.execute(with: action) }
        }
        
        self.commitProcedure = commitProcedure
        
        actions = .init(dispatcher: dispatcher)
        computed = .init(state: state)
        
        dispatcherKey = dispatcher.subscribe(commit)
        sharedDispatcherKey = sharedDispatcher.subscribe(commit)
    }
    
    deinit {
        commitProcedure.cancel()
        dispatcher.unsubscribe(for: dispatcherKey)
        sharedDispatcher.unsubscribe(for: sharedDispatcherKey)
    }
}

/// Represents a proxy for functions to mutate a State.
public protocol Mutations {
    associatedtype State
    associatedtype Action
    
    /// Mutate a state by given action.
    /// The only way to actually mutate state in a Store.
    func commit(action: Action, state: State)
}

/// A proxy of functions for dispatching actions.
public struct Actions<State, Action> {
    private let dispatcher: Dispatcher<State, Action>
    
    /// Create the proxy.
    ///
    /// - Parameters:
    ///   - dispather: A dispatcher to dispatch the actions to.
    fileprivate init(dispatcher: Dispatcher<State, Action>) {
        self.dispatcher = dispatcher
    }
    
    /// Dispatch given action to dispatcher.
    ///
    /// - Parameters:
    ///   - action: An action to be dispatch.
    public func dispatch(action: Action) {
        dispatcher.dispatch(action: action)
    }
}

/// A proxy of properties to be published of State.
public struct Computed<State> {
    /// A state to be publish properties by `self`.
    public let state: State
    
    /// Create the proxy.
    ///
    /// - Parameters:
    ///   - state: A state to be proxied.
    fileprivate init(state: State) {
        self.state = state
    }
}
