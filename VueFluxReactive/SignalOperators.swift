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
            self.subscribe { value in
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
            let subscriptionScope = SubscriptionScope()
            subscriptionScope += self.subscribe { value in
                executor.execute {
                    guard !subscriptionScope.isUnsubscribed else { return }
                    send(value)
                }
            }
            return subscriptionScope
        }
    }
}
