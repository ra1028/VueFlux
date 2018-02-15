/// An action dispatcher for subscribed dispatch functions.
final class Dispatcher<State: VueFlux.State> {
    typealias Observers = Storage<(State.Action) -> Void>
    
    /// Shared instance associated by generic type of State.
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let observers = AtomicReference(Observers())
    
    /// Create a Dispatcher
    init() {}
    
    /// Dispatch an action for all subscribed observers.
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
    
    /// Subscribe an observer in order to observe `self` for all actions being dispatched.
    ///
    /// - Parameters:
    ///   - observer: A function to be received the actions.
    ///
    /// - Returns: A key for remove given observer.
    @discardableResult
    func subscribe(_ observer: @escaping (State.Action) -> Void) -> Observers.Key {
        return observers.modify { observers in
            observers.add(observer)
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
