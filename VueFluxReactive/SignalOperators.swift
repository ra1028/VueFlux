import VueFlux

public extension Signal {
    /// Map each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that to transform each values to a new value.
    ///
    /// - Returns: A signal to be receives new values.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return .init { observer in
            self.subscribe { value in
                observer(transform(value))
            }
        }
    }
    
    /// Forward all events onto the given executor.
    ///
    /// - Parameters:
    ///   - executor: A executor to forward events on.
    ///
    /// - returns: A signal that will forward values on given executor.
    public func observe(on executor: Executor) -> Signal<Value> {
        return .init { observer in
            self.subscribe { value in
                executor.execute { observer(value) }
            }
        }
    }
}
