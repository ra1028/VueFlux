import ReactiveSwift
import enum Result.NoError

public struct Dispatcher<State: VueFlux.State> {
    private let (signal, observer) = Signal<State.Action, NoError>.pipe()

    public init() {}

    public func dispatch(action: State.Action) {
        observer.send(value: action)
    }

    public func bind(store: Store<State>, on scheduler: Scheduler) -> Disposable? {
        return signal
            .observe(on: scheduler)
            .observeValues { [weak store] action in store?.dispatch(action: action) }
    }
}

public class Store<State: VueFlux.State> {
    public let state: State
    private let mutations: State.Mutations
    private let dispatcher: Dispatcher<State>
    private let disposable = ScopedDisposable<SerialDisposable>(.init())

    public var actions: Actions<State> {
        return .init(dispatcher: dispatcher)
    }

    public init(state: State, mutations: State.Mutations, dispatcher: Dispatcher<State> = .init(), scheduler: Scheduler = QueueScheduler()) {
        self.state = state
        self.mutations = mutations
        self.dispatcher = dispatcher
        self.disposable.inner.inner = dispatcher.bind(store: self, on: scheduler)
    }

    fileprivate func dispatch(action: State.Action) {
        self.mutations.commit(action: action, state: state)
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
    public typealias Dispatcher = VueFlux.Dispatcher<State>

    private let dispatcher: Dispatcher

    fileprivate init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
    }

    public func dispatch(action: State.Action) {
        dispatcher.dispatch(action: action)
    }
}

