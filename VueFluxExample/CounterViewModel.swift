import VueFlux
import ReactiveSwift

extension Reactive where Base == CounterViewModel {
    var count: Property<Int> {
        return .init(base.count)
    }
}

final class CounterViewModel: State, ReactiveExtensionsProvider {
    typealias Action = CounterAction
    
    fileprivate let count = MutableProperty(0)
}

extension CounterViewModel {
    struct Mutations: VueFlux.Mutations {
        func commit(action: Action, state: CounterViewModel) {
            switch action {
            case .increment:
                state.count.value += 1
                
            case .decrement:
                state.count.value -= 1
            }
        }
    }
}
