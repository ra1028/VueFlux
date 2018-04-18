import Foundation

final class AtomicBool: ExpressibleByBooleanLiteral {
    private let rawValue = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    
    var value: Bool {
        return rawValue.pointee == true.int32Value
    }
    
    init(booleanLiteral value: Bool) {
        rawValue.initialize(to: value.int32Value)
    }
    
    deinit {
        rawValue.deinitialize(count: 1)
        rawValue.deallocate()
    }
    
    func compareAndSwapBarrier(old: Bool, new: Bool) -> Bool {
        return OSAtomicCompareAndSwap32Barrier(old.int32Value, new.int32Value, rawValue)
    }
}

private extension Bool {
    var int32Value: Int32 {
        return self ? 1 : 0
    }
}
