import RxSwift
import RxCocoa

public struct Dispatcher<State: VueFlux.State> {
    public static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let relay = PublishRelay<State.Action>()

    public init() {}

    public func dispatch(action: State.Action) {
        relay.accept(action)
    }

    public func register(store: Store<State>, on scheduler: ImmediateSchedulerType) -> Disposable {
        return relay
            .observeOn(scheduler)
            .subscribe(onNext: { [weak store] action in store?.dispatch(action: action) })
    }
}

public class Store<State: VueFlux.State> {
    private let state: State
    private let mutations: State.Mutations
    private let dispatcher = Dispatcher<State>()
    private let disposeBag = DisposeBag()

    public static var actions: Actions<State> {
        return .init(dispatcher: Dispatcher<State>.shared)
    }
    
    public lazy var actions: Actions<State> = .init(dispatcher: dispatcher)
    public lazy var expose: Expose<State> = .init(state: state)

    public init(state: State, mutations: State.Mutations, scheduler: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
        self.state = state
        self.mutations = mutations
        
        dispatcher.register(store: self, on: scheduler).disposed(by: disposeBag)
        Dispatcher<State>.shared.register(store: self, on: scheduler).disposed(by: disposeBag)
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

private final class DispatcherContext {
    static let shared = DispatcherContext()
    
    private var dispatchers = [Identifier: Any]()
    private let lock = NSLock()
    
    private init() {}
    
    func dispatcher<State: VueFlux.State>(for type: State.Type) -> Dispatcher<State> {
        lock.lock()
        lock.unlock()
        
        let identifier = Identifier(type: type)
        if let dispatcher = dispatchers[identifier] as? Dispatcher<State> {
            return dispatcher
        }
        
        let dispatcher = Dispatcher<State>()
        dispatchers[identifier] = dispatcher
        return dispatcher
    }
}

private extension DispatcherContext {
    private struct Identifier: Hashable {
        let hashValue: Int
        
        init<State: VueFlux.State>(type: State.Type) {
            hashValue = String(reflecting: type).hashValue
        }
        
        static func ==(lhs: Identifier, rhs: Identifier) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
}
