import VueFlux

/// A wrapper for automatically dispose added all disposables.
public final class DisposableScope: Disposable {
    private enum State {
        case active(disposables: ContiguousArray<Disposable>)
        case disposed
    }
    
    /// A Bool value indicating whether disposed.
    public var isDisposed: Bool {
        guard case .disposed = state.value else { return false }
        return true
    }
    
    private let state: ThreadSafe<State>
    
    deinit {
        dispose()
    }
    
    /// Initialize a new DisposableScope with the disposables.
    ///
    /// - Parameters:
    ///   - disposables: Sequence of something conformed to Disposable.
    public init<Sequence: Swift.Sequence>(_ disposebles: Sequence) where Sequence.Element == Disposable {
        state = .init(.active(disposables: .init(disposebles)))
    }
    
    /// Initialize a new, empty DisposableScope.
    public convenience init() {
        self.init([])
    }
    
    /// Add a new Disposable to a scope.
    ///
    /// - Parameters:
    ///   - disposable: A disposable to be add to scope.
    public func add(disposable: Disposable) {
        state.modify { state in
            guard case var .active(disposables) = state else {
                disposable.dispose()
                return
            }
            disposables.append(disposable)
            state = .active(disposables: disposables)
        }
    }
    
    /// Dispose all disposables if not already been disposed.
    public func dispose() {
        guard case let .active(disposables) = state.swap(.disposed) else { return }
        
        for disposable in disposables {
            disposable.dispose()
        }
    }
    
    /// An operator for add a new disposable to a scope.
    ///
    /// - Parameters:
    ///   - disposableScope: A scope to be add new disposable.
    ///   - disposable: A disposable to be add to scope.
    public static func += (disposableScope: DisposableScope, disposable: Disposable) {
        disposableScope.add(disposable: disposable)
    }
}
