import RxSwift
import RxCocoa

public struct Dispatcher<Action> {
    private let replay = PublishRelay<Action>()
    
    public var actions: Actions<Action> {
        return .init(dispatcher: self)
    }

    public init() {}

    public func dispatch(action: Action) {
        replay.accept(action)
    }

    public func register<State>(store: Store<State>, on scheduler: ImmediateSchedulerType) -> Disposable where State.Action == Action {
        return replay
            .observeOn(scheduler)
            .subscribe(onNext: { [weak store] action in store?.dispatch(action: action) })
    }
}

public class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State.Action>()
    private let disposeBag = DisposeBag()

    public var actions: Actions<State.Action> {
        return dispatcher.actions
    }
    
    public var export: Export<State> {
        return .init(state: state)
    }

    public init(state: State, mutations: State.Mutations, scheduler: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
        self.state = state
        self.mutations = mutations
        dispatcher.register(store: self, on: scheduler).disposed(by: disposeBag)
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

public struct Actions<Action> {
    public typealias Dispatcher = VueFlux.Dispatcher<Action>

    private let dispatcher: Dispatcher

    fileprivate init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
    }

    public func dispatch(action: Action) {
        dispatcher.dispatch(action: action)
    }
}

public struct Export<State: VueFlux.State> {
    public let state: State
    
    fileprivate init(state: State) {
        self.state = state
    }
}
