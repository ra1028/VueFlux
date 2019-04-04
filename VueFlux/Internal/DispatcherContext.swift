/// Shared instance provider for Dispatcher.
struct DispatcherContext {
    static let shared = DispatcherContext()
    
    private let dispatchers = AtomicReference([ObjectIdentifier: Any]())
    
    private init() {}
    
    /// Provide a shared instance of Dispatcher.
    ///
    /// - Parameters:
    ///   - stateType: State protocol conformed type for Dispatcher.
    ///
    /// - Returns: An shared instance of Dispatcher.
    func dispatcher<State, Action>(for dispatcherType: Dispatcher<State, Action>.Type) -> Dispatcher<State, Action> {
        return dispatchers.modify { dispatchers in
            let identifier = ObjectIdentifier(dispatcherType)
            if let dispatcher = dispatchers[identifier] as? Dispatcher<State, Action> {
                return dispatcher
            }
            
            let dispatcher = Dispatcher<State, Action>()
            dispatchers[identifier] = dispatcher
            return dispatcher
        }
    }
}
