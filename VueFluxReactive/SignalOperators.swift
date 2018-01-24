import VueFlux

public extension Signal {
    /// Map each values to a new value.
    ///
    /// - Parameters:
    ///   - transform: A function that to transform each values to a new value.
    ///
    /// - Returns: A signal to be receives new values.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Signal<T> {
        return .init { send in
            self.observe { value in
                send(transform(value))
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
        return .init { send in
            let workItem = Executor.WorkItem(send)
            
            let disposable = self.observe { value in
                executor.execute(workItem: workItem, with: value)
            }
            
            return AnyDisposable {
                workItem.cancel()
                disposable.dispose()
            }
        }
    }
}
