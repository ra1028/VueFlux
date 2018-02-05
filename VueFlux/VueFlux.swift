/// Manages a State and commits the action received via dispatcher to mutations.
open class Store<State: VueFlux.State> {
    private let dispatcher = Dispatcher<State>()
    private let sharedDispatcher = Dispatcher<State>.shared
    
    private let commitWorkItem: Executor.WorkItem<State.Action>
    private let dispatcherKey: Dispatcher<State>.Observers.Key
    private let sharedDispatcherKey: Dispatcher<State>.Observers.Key
    
    /// An action proxy that dispatches actions via shared dispatcher.
    /// Action is dispatched to all stores which have same generic type of State.
    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    /// A action proxy that dispatches actions via dispatcher retained by `self`.
    public lazy var actions = Actions<State>(dispatcher: dispatcher)
    
    /// A proxy for computed properties to be published of State.
    public let computed: Computed<State>
    
    /// Initialize a new store.
    ///
    /// - Parameters:
    ///   - state: A state to be managed in `self`.
    ///   - mutations: A mutations for mutates the state.
    ///   - executor: An executor to dispatch actions on.
    public init(state: State, mutations: State.Mutations, executor: Executor) {
        let commitWorkItem = Executor.WorkItem<State.Action> { action in
            mutations.commit(action: action, state: state)
        }
        
        let commit: (State.Action) -> Void = { action in
            executor.execute(workItem: commitWorkItem, with: action)
        }
        
        self.commitWorkItem = commitWorkItem
        computed = .init(state: state)
        dispatcherKey = dispatcher.subscribe(commit)
        sharedDispatcherKey = sharedDispatcher.subscribe(commit)
    }
    
    deinit {
        commitWorkItem.cancel()
        dispatcher.unsubscribe(for: dispatcherKey)
        sharedDispatcher.unsubscribe(for: sharedDispatcherKey)
    }
}

/// Represents a state can be managed in Store.
public protocol State: class {
    associatedtype Action
    associatedtype Mutations: VueFlux.Mutations where Mutations.State == Self
}

/// Represents a proxy for functions to mutate a State.
public protocol Mutations {
    associatedtype State: VueFlux.State
    
    /// Mutate a state by given action.
    /// The only way to actually mutate state in a Store.
    func commit(action: State.Action, state: State)
}

/// A proxy of functions for dispatching actions.
public struct Actions<State: VueFlux.State> {
    private let dispatcher: Dispatcher<State>
    
    /// Create the proxy.
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

/// A proxy of properties to be published of State.
public struct Computed<State: VueFlux.State> {
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
