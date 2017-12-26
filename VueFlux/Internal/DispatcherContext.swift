/// Shared instance provider for Dispatcher.
struct DispatcherContext {
    static let shared = DispatcherContext()
    
    private let dispatchers = ThreadSafe([Identifier: Any]())
    
    private init() {}
    
    /// Provide a shared instance of Dispatcher.
    ///
    /// - Parameters:
    ///   - stateType: State protocol conformed type for Dispatcher.
    ///
    /// - Returns: An shared instance of Dispatcher.
    func dispatcher<State: VueFlux.State>(for stateType: State.Type) -> Dispatcher<State> {
        return dispatchers.modify { dispatchers in
            let identifier = Identifier(for: stateType)
            if let dispatcher = dispatchers[identifier] as? Dispatcher<State> {
                return dispatcher
            }
            
            let dispatcher = Dispatcher<State>()
            dispatchers[identifier] = dispatcher
            return dispatcher
        }
    }
}

private extension DispatcherContext {
    /// Identifier for save dispatcher instance.
    struct Identifier: Hashable {
        let hashValue: Int
        
        /// Create with arbitrary State protocol conformed type.
        /// - Parameters:
        ///   - stateType: Type of state to make Dispatcher unique.
        init<State: VueFlux.State>(for stateType: State.Type) {
            hashValue = String(reflecting: stateType).hashValue
        }
        
        /// Compare whether two identifiers are equal.
        ///
        /// - Parameters:
        ///   - lhs: An identifier to compare.
        ///   - rhs: Another identifier to compare.
        ///
        /// - Returns: A Bool value indicating whether two identifiers are equal.
        static func == (lhs: Identifier, rhs: Identifier) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
}
