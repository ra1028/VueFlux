import VueFlux

public extension Signal {
    /// Map each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that to transform each values to a new value.
    ///
    /// - Returns: A signal to be receives new values.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return operated { value, send in
            send(transform(value))
        }
    }
    
    /// Forward all events onto the given executor.
    ///
    /// - Parameters:
    ///   - executor: A executor to forward events on.
    ///
    /// - returns: A signal that will forward values on given executor.
    public func observe(on executor: Executor) -> Signal<Value> {
        return operated { value, send in
            executor.execute { send(value) }
        }
    }
}

private extension Signal {
    func operated<T>(_ operation: @escaping (Value, @escaping (T) -> Void) -> Void) -> Signal<T> {
        return .init { send in
            self.observe { value in
                operation(value, send)
            }
        }
    }
}
