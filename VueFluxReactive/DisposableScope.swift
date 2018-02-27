import VueFlux

/// A container that automatically dispose all added disposables when deinitialized.
/// Itself also behaves as Disposable.
public final class DisposableScope: Disposable {
    /// A Bool value indicating whether disposed.
    public var isDisposed: Bool {
        return _isDisposed.value
    }
    
    private let _isDisposed: AtomicBool = false
    private var disposables: ContiguousArray<Disposable>?
    
    deinit {
        dispose()
    }
    
    /// Initialize a new DisposableScope with the disposables.
    ///
    /// - Parameters:
    ///   - disposables: Sequence of something conformed to Disposable.
    public init<Sequence: Swift.Sequence>(_ disposebles: Sequence) where Sequence.Element == Disposable {
        self.disposables = .init(.init(disposebles))
    }
    
    /// Initialize a new, empty DisposableScope.
    public convenience init() {
        self.init([])
    }
    
    /// Add a new Disposable to a scope if not already disposed.
    ///
    /// - Parameters:
    ///   - disposable: A disposable to be add to scope.
    public func add(disposable: Disposable) {
        guard !isDisposed, !disposable.isDisposed else { return disposable.dispose() }
        disposables?.append(disposable)
    }
    
    /// Dispose all disposables if not already been disposed.
    public func dispose() {
        guard _isDisposed.compareAndSwapBarrier(old: false, new: true), let disposables = disposables else { return }
        self.disposables = nil
        
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
