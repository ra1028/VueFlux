/// An collection of values of type `Element` that to be able to remove value by key.
struct Storage<Element> {
    private var buffer = ContiguousArray<(key: Key, element: Element)>()
    private var nextKey = Key.first
    
    /// Append a new element.
    ///
    /// - Parameters:
    ///   - element: An element to be append.
    ///
    /// - Returns: A key for remove given element.
    mutating func append(_ element: Element) -> Key {
        let key = nextKey
        nextKey = key.next
        buffer.append((key: key, element: element))
        return key
    }
    
    /// Remove an element for given key.
    ///
    /// - Parameters:
    ///   - key: A key for remove element.
    mutating func remove(for key: Key) {
        for index in buffer.startIndex..<buffer.endIndex where buffer[index].key == key {
            buffer.remove(at: index)
            break
        }
    }
    
    /// Calls the given function on each element in the collection.
    ///
    /// - Parameters:
    ///   - body: A function that takes an element of the collection as a parameter.
    func forEach(_ body: (Element) -> Void) {
        for (_, element) in buffer {
            body(element)
        }
    }
}

extension Storage {
    /// An unique key for remove element.
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
