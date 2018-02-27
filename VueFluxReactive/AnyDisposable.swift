import VueFlux

/// Disposable that consist of any function.
public final class AnyDisposable: Disposable {
    /// A Bool value indicating whether disposed.
    public var isDisposed: Bool {
        return _isDisposed.value
    }
    
    private let _isDisposed: AtomicBool = false
    private var _dispose: (() -> Void)?
    
    /// Create with dispose function.
    ///
    /// - Parameters:
    ///   - dispose: A function to run when disposed.
    public init(_ dispose: @escaping () -> Void) {
        _dispose = dispose
    }
    
    /// Dispose if not already been disposed.
    public func dispose() {
        guard _isDisposed.compareAndSwapBarrier(old: false, new: true) else { return }
        _dispose?()
        _dispose = nil
    }
}
