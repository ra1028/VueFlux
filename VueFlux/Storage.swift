/// Collection of values of type `Element` that to be able to remove value by key.
public struct Storage<Element> {
    private var elements = ContiguousArray<Element>()
    private var keyRawValues = ContiguousArray<Key.RawValue>()
    private var nextKey = Key.first
    
    /// Create the new, empty storage.
    public init() {}
    
    /// Add a new element.
    ///
    /// - Parameters:
    ///   - element: An element to be added.
    ///
    /// - Returns: A key for remove given element.
    @discardableResult
    public mutating func add(_ element: Element) -> Key {
        let key = nextKey
        nextKey = key.next
        
        elements.append(element)
        keyRawValues.append(key.rawValue)
        
        return key
    }
    
    /// Remove an element for given key.
    ///
    /// - Parameters:
    ///   - key: A key for remove element.
    ///
    /// - Returns: A removed element.
    @discardableResult
    public mutating func remove(for key: Key) -> Element? {
        guard let index = indices.first(where: { keyRawValues[$0] == key.rawValue }) else { return nil }
        
        keyRawValues.remove(at: index)
        return elements.remove(at: index)
    }
}

extension Storage: RandomAccessCollection {
    public var startIndex: Int {
        return elements.startIndex
    }
    
    public var endIndex: Int {
        return elements.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(position: Int) -> Element {
        return elements[position]
    }
}

public extension Storage {
    /// An unique key for remove element.
    public struct Key {
        fileprivate typealias RawValue = UInt64
        
        fileprivate let rawValue: RawValue
        
        fileprivate static var first: Key {
            return .init(rawValue: 0)
        }
        
        fileprivate var next: Key {
            return .init(rawValue: rawValue &+ 1)
        }
        
        private init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
    }
}
