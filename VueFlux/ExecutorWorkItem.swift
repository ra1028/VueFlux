public extension Executor {
    /// Encapsulates the function to execute by Executor.
    /// Also be able to cancel its execution.
    public final class WorkItem<Value> {
        /// A Bool value indicating whether canceled.
        public var isCanceled: Bool {
            return _isCanceled.value
        }
        
        private let _isCanceled: AtomicBool = false
        private var _execute: ((Value) -> Void)?
        
        /// Create with an arbitrary function.
        ///
        /// - Parameters:
        ///   - execute: A function to be executed by calling `execute(with:)` until canceled.
        public init(_ execute: @escaping (Value) -> Void) {
            _execute = execute
        }
        
        /// Synchronously execute the specified function.
        ///
        /// - Parameters:
        ///   - value: A value to be pass to specified function.
        public func execute(with value: @autoclosure () -> Value) {
            guard !isCanceled, let execute = _execute else { return }
            execute(value())
        }
        
        /// Cancel the specified function.
        /// Cancellation does not affect any execution of the function that is already in progress.
        public func cancel() {
            guard _isCanceled.compareAndSwapBarrier(old: false, new: true) else { return }
            _execute = nil
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
