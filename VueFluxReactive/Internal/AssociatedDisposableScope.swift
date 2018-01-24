import ObjectiveC

extension DisposableScope {
    /// Take a DisposableScope associated with given object.
    ///
    /// - Prameters:
    ///   - object: An object that associates with DisposableScope.
    ///
    /// - Returns: A DisposableScope associated with given object.
    static func associated(with object: AnyObject) -> DisposableScope {
        struct Keys {
            static let disposableScope = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
        }
        
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        if let disposableScope = objc_getAssociatedObject(object, Keys.disposableScope) as? DisposableScope {
            return disposableScope
        }
        
        let disposableScope = DisposableScope()
        objc_setAssociatedObject(object, Keys.disposableScope, disposableScope, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return disposableScope
    }
}
