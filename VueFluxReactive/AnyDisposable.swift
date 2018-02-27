import VueFlux

/// Disposable that consist of any function.
public struct AnyDisposable: Disposable {
    private enum State {
        case active(dispose: () -> Void)
        case disposed
    }
    
    /// A Bool value indicating whether disposed.
    public var isDisposed: Bool {
        return _dispose.value == nil
    }
    
    private let _dispose: AtomicReference<(() -> Void)?>
    
    /// Create with dispose function.
    ///
    /// - Parameters:
    ///   - dispose: A function to run when disposed.
    public init(_ dispose: @escaping () -> Void) {
        _dispose = .init(dispose)
    }
    
    /// Dispose if not already been disposed.
    public func dispose() {
        guard let dispose = _dispose.swap(nil) else { return }
        dispose()
    }
}
