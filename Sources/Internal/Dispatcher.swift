/// An action dispatcher for subscribed dispatch functions.
/// Can be unsubscribe it.
struct Dispatcher<State: VueFlux.State> {
    private typealias Subscription = (key: Key, observer: (State.Action) -> Void)
    private typealias Buffer = (nextKey: Key, subscriptions: ContiguousArray<Subscription>)
    
    /// Shared instance associated by `State` type.
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let buffer = Atomic<Buffer>((nextKey: .first, subscriptions: []))
    
    /// Construct a Dispatcher
    init() {}
    
    /// Dispatch an action for all subscribed dispatch functions.
    ///
    /// - Parameters:
    ///   - action: An Action to be dispatch.
    func dispatch(action: State.Action) {
        buffer.synchronized { buffer in
            for entry in buffer.subscriptions {
                entry.observer(action)
            }
        }
    }
    
    /// Subscribe a dispatch function.
    /// The function is performed on executor.
    ///
    /// - Parameters:
    ///   - executor: An executor to dispatch actions on.
    ///   - dispatch: A function to be called with action.
    ///
    /// - Returns: A key for unsubscribe a dispatch function.
    func subscribe(executor: Executor, dispatch: @escaping (State.Action) -> Void) -> Key {
        return buffer.modify { buffer in
            let key = buffer.nextKey
            buffer.nextKey = key.next
            
            let observer: (State.Action) -> Void = { action in
                executor.execute { dispatch(action) }
            }
            
            buffer.subscriptions.append((key: key, observer: observer))
            return key
        }
    }
    
    /// Unsubscribe a dispatch function.
    ///
    /// - Parameters:
    ///   - key: A key given when subscribing.
    func unsubscribe(for key: Key) {
        buffer.modify { buffer in
            for index in buffer.subscriptions.startIndex..<buffer.subscriptions.endIndex where buffer.subscriptions[index].key == key {
                buffer.subscriptions.remove(at: index)
                break
            }
        }
    }
}

extension Dispatcher {
    /// A unique key for unsubscribe dispatch functions.
    struct Key: Equatable {
        private let value: UInt64
        
        /// Construct a first key
        static var first: Key {
            return .init(value: 0)
        }
        
        /// Construct a next key
        var next: Key {
            return .init(value: value &+ 1)
        }
        
        private init(value: UInt64) {
            self.value = value
        }
        
        /// Compare whether two keys are equal.
        ///
        /// - Parameters:
        ///   - lhs: A key to compare.
        ///   - rhs: Another key to compare.
        ///
        /// - Returns: A Bool value indicating whether two keys are equal.
        static func == (lhs: Key, rhs: Key) -> Bool {
            return lhs.value == rhs.value
        }
    }
}
