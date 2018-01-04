/// An action dispatcher for subscribed dispatch functions.
struct Dispatcher<State: VueFlux.State> {
    typealias Observers = Storage<(State.Action) -> Void>
    
    /// Shared instance associated by generic type of State.
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let observers = ThreadSafe(Observers())
    
    /// Create a Dispatcher
    init() {}
    
    /// Dispatch an action for all subscribed dispatch functions.
    ///
    /// - Parameters:
    ///   - action: An Action to be dispatch.
    func dispatch(action: State.Action) {
        observers.synchronized { observers in
            for observer in observers {
                observer(action)
            }
        }
    }
    
    /// Subscribe a dispatch function.
    /// The function is performed on executor.
    ///
    /// - Parameters:
    ///   - executor: An executor to dispatch actions on.
    ///   - dispatch: A function to be called with action.
    ///
    /// - Returns: A subscription to be able to unsubscribe.
    @discardableResult
    func subscribe(executor: Executor, dispatch: @escaping (State.Action) -> Void) -> Observers.Key {
        return observers.modify { observers in
            observers.add { action in
                executor.execute { dispatch(action) }
            }
        }
    }
    
    /// Unsubscribe a dispatch function.
    ///
    /// - Parameters:
    ///   - key: A key for unsubscribe observer.
    func unsubscribe(for key: Observers.Key) {
        observers.modify { observers in
            observers.remove(for: key)
        }
    }
}
