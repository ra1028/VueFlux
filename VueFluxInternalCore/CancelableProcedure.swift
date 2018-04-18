/// Encapsulate the function and make it cancelable.
/// A function will not be executed after canceling, except already in progress execution.
final class CancelableProcedure<Value> {
    /// A Bool value indicating whether canceled.
    var isCanceled: Bool {
        return _isCanceled.value
    }
    
    private let _isCanceled: AtomicBool = false
    private var _execute: ((Value) -> Void)?
    
    /// Initialize with an arbitrary function.
    ///
    /// - Parameters:
    ///   - execute: A function to be executed by calling `execute(with:)` until canceled.
    init(_ execute: @escaping (Value) -> Void) {
        _execute = execute
    }
    
    /// Synchronously execute the specified function.
    ///
    /// - Parameters:
    ///   - value: A value to be pass to specified function.
    func execute(with value: @autoclosure () -> Value) {
        guard !isCanceled, let execute = _execute else { return }
        execute(value())
    }
    
    /// Cancel the specified function.
    /// Cancellation does not affect already in progress execution.
    func cancel() {
        guard _isCanceled.compareAndSwapBarrier(old: false, new: true) else { return }
        _execute = nil
    }
}

extension CancelableProcedure where Value == Void {
    /// Synchronously execute the specified function.
    @inline(__always)
    func execute() {
        self.execute(with: ())
    }
}
