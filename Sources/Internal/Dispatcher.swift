struct Dispatcher<State: VueFlux.State> {
    private typealias Subscription = (key: Key, observer: (State.Action) -> Void)
    private typealias Buffer = (nextKey: Key, subscriptions: ContiguousArray<Subscription>)
    
    static var shared: Dispatcher<State> {
        return DispatcherContext.shared.dispatcher(for: State.self)
    }
    
    private let buffer = Atomic<Buffer>((nextKey: .first, subscriptions: []))
    
    init() {}
    
    func dispatch(action: State.Action) {
        buffer.synchronized { buffer in
            for entry in buffer.subscriptions {
                entry.observer(action)
            }
        }
    }
    
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
    struct Key: Equatable {
        private let value: UInt64
        
        static var first: Key {
            return .init(value: 0)
        }
        
        var next: Key {
            return .init(value: value &+ 1)
        }
        
        private init(value: UInt64) {
            self.value = value
        }
        
        static func == (lhs: Key, rhs: Key) -> Bool {
            return lhs.value == rhs.value
        }
    }
}
