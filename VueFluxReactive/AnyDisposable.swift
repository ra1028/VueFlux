import VueFlux

/// Disposable that consist of any function.
public struct AnyDisposable: Disposable {
    private enum State {
        case active(dispose: () -> Void)
        case disposed
    }
    
    private let state: ThreadSafe<State>
    
    /// A Bool value indicating whether disposed.
    public var isDisposed: Bool {
        guard case .disposed = state.value else { return false }
        return true
    }
    
    /// Create with dispose function.
    ///
    /// - Parameters:
    ///   - dispose: A function to run when disposed.
    public init(_ dispose: @escaping () -> Void) {
        state = .init(.active(dispose: dispose))
    }
    
    /// Dispose if not already been disposed.
    public func dispose() {
        guard case let .active(dispose) = state.swap(.disposed) else { return }
        dispose()
    }
}
