protocol ReactiveVariable: Subscribable {
    var value: Value { get }
    var signal: Signal<Value> { get }
}
