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
