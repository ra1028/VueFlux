import Foundation

public struct Executor {
    public static var immediate: Executor {
        return .init { execute in execute() }
    }
    
    public static var mainThread: Executor {
        let innerExecutor = MainThreadInnerExecutor()
        return .init(innerExecutor.execute(_:))
    }
    
    public static func queue(_ dispatchQueue: DispatchQueue) -> Executor {
        return .init { execute in dispatchQueue.async(execute: execute) }
    }
    
    private let executor: (@escaping () -> Void) -> Void
    
    private init(_ executor: @escaping (@escaping () -> Void) -> Void) {
        self.executor = executor
    }
    
    public func execute(_ body: @escaping () -> Void) {
        executor(body)
    }
}

private extension Executor {
    final class MainThreadInnerExecutor {
        private let executingCount = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        init() {
            executingCount.initialize(to: 0)
        }
        
        deinit {
            executingCount.deinitialize()
            executingCount.deallocate(capacity: 1)
        }
        
        func execute(_ action: @escaping () -> Void) {
            let count = OSAtomicIncrement32(executingCount)
            
            if Thread.isMainThread && count == 1 {
                action()
                OSAtomicDecrement32(executingCount)
            } else {
                DispatchQueue.main.async {
                    action()
                    OSAtomicDecrement32(self.executingCount)
                }
            }
        }
    }
}
