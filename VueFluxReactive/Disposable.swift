/// Represents something that can be disposed.
public protocol Disposable {
    /// A Bool value indicating whether disposed.
    var isDisposed: Bool { get }
    
    /// Dispose if not already been disposed.
    func dispose()
}
