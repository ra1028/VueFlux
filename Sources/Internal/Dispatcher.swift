/// An action dispatcher for subscribed dispatch functions.
final class Dispatcher<State: VueFlux.State> {
    /// Shared instance associated by `State` type.
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let observers = Atomic(Storage<(State.Action) -> Void>())
    
    /// Construct a Dispatcher
    init() {}
    
    /// Dispatch an action for all subscribed dispatch functions.
    ///
    /// - Parameters:
    ///   - action: An Action to be dispatch.
    func dispatch(action: State.Action) {
        observers.synchronized { observers in
            observers.forEach { observer in
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
    func subscribe(executor: Executor, dispatch: @escaping (State.Action) -> Void) -> Subscription {
        return observers.modify { observers in
            let key = observers.append { action in
                executor.execute { dispatch(action) }
            }
            
            return .init { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
}
