import VueFlux

/// A stream that able to both sends and receive values.
final class Stream<Value> {
    private lazy var observers = AtomicReference(Storage<(Value) -> Void>())
    
    /// Observe `self` for all values being sended.
    ///
    /// - Prameters:
    ///   - observer: A function to be received the values.
    ///
    /// - Returns: A disposable to remove given observer from `self`.
    @discardableResult
    func observe(_ observer: @escaping (Value) -> Void) -> Disposable {
        let key = observers.modify { observers in
            observers.add(observer)
        }
        
        return AnyDisposable { [weak self] in
            self?.observers.modify { observers in
                observers.remove(for: key)
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
