import Foundation

/// Executor for executes arbitrary function on a certain context.
public struct Executor {
    public typealias Context = (@escaping () -> Void) -> Void
    
    /// Executes function immediately and synchronously.
    public static var immediate: Executor {
        return .init { function in function() }
    }
    
    /// Executes function on main-thread.
    /// If called execute on main-thread, function is not enqueue and execute immediately.
    public static var mainThread: Executor {
        let innerExecutor = MainThreadInnerExecutor()
        return .init(innerExecutor.execute(_:))
    }
    
    /// All the executions are enqueued to given qeueue.
    public static func queue(_ dispatchQueue: DispatchQueue) -> Executor {
        return .init { function in dispatchQueue.async(execute: function) }
    }
    
    private let context: Context
    
    /// Create with executor function.
    ///
    /// - Parameters:
    ///   - context: A function to that executes other function.
    public init(_ context: @escaping Context) {
        self.context = context
    }
    
    /// Execute an arbitrary function.
    ///
    /// - Parameters:
    ///   - function: A function to be execute.
    public func execute(_ function: @escaping () -> Void) {
        context(function)
    }
}

private extension Executor {
    /// Inner executor that serial execute on main thread.
    final class MainThreadInnerExecutor {
        private let executingCount = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        /// Initialize a inner executor.
        init() {
            executingCount.initialize(to: 0)
        }
        
        deinit {
            executingCount.deinitialize()
            executingCount.deallocate(capacity: 1)
        }
        
        /// Serial execute a function on main thread.
        ///
        /// - Parameters:
        ///   - function: A function to be execute.
        func execute(_ function: @escaping () -> Void) {
            let count = OSAtomicIncrement32(executingCount)
            
            if Thread.isMainThread && count == 1 {
                function()
                OSAtomicDecrement32(executingCount)
            } else {
                DispatchQueue.main.async {
                    function()
                    OSAtomicDecrement32(self.executingCount)
                }
            }
        }
    }
}
