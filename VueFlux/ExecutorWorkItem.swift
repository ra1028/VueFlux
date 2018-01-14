public extension Executor {
    /// Encapsulates the function to execute by Executor.
    /// Also be able to cancel its execution.
    public struct WorkItem<Value> {
        private enum State {
            case active(function: (Value) -> Void)
            case canceled
        }
        
        private let state: ThreadSafe<State>
        
        /// A Bool value indicating whether canceled.
        public var isCanceled: Bool {
            guard case .canceled = state.value else { return false }
            return true
        }
        
        /// Create with an arbitrary function.
        ///
        /// - Parameters:
        ///   - function: A function to be executed by calling `execute(with:)` until canceled.
        public init(_ function: @escaping (Value) -> Void) {
            state = .init(.active(function: function))
        }
        
        /// Synchronously execute the specified function.
        ///
        /// - Parameters:
        ///   - value: A value to be pass to specified function.
        public func execute(with value: Value) {
            guard case let .active(function) = state.value else { return }
            function(value)
        }
        
        /// Cancel the specified function.
        /// Cancellation does not affect any execution of the function that is already in progress.
        public func cancel() {
            state.value = .canceled
        }
    }
}

public extension Executor.WorkItem where Value == Void {
    /// Synchronously execute the specified function.
    @inline(__always)
    public func execute() {
        self.execute(with: ())
    }
}
