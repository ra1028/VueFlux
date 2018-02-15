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
    func dispatcher<State: VueFlux.State>(for stateType: State.Type) -> Dispatcher<State> {
        return dispatchers.modify { dispatchers in
            let identifier = ObjectIdentifier(stateType)
            if let dispatcher = dispatchers[identifier] as? Dispatcher<State> {
                return dispatcher
            }
            
            let dispatcher = Dispatcher<State>()
            dispatchers[identifier] = dispatcher
            return dispatcher
        }
    }
}
