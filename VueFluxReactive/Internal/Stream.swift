import VueFlux

/// A stream that able to both sends and receive values.
final class Stream<Value> {
    private lazy var observers = ThreadSafe(Storage<(Value) -> Void>())
    
    /// Add the observer function to be received the values.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A disposable to remove given observer from `self`.
    @discardableResult
    func add(observer: @escaping (Value) -> Void) -> Disposable {
        return observers.modify { observers in
            let key = observers.add(observer)
            
            return AnyDisposable { [weak self] in
                self?.observers.modify { observers in
                    observers.remove(for: key)
                }
            }
        }
    }
    
    /// Send arbitrary value to all added observers.
    ///
    /// - Parameters:
    ///   - value: Value to send to all observers.
    func send(value: Value) {
        observers.synchronized { observers in
            for observer in observers {
                observer(value)
            }
        }
    }
}
