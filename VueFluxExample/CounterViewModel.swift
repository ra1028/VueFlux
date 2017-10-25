import VueFlux
import ReactiveSwift

extension Export where State == CounterViewModel {
    var count: Property<Int> {
        return .init(state.count)
    }
}

final class CounterViewModel: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let count = MutableProperty(0)
}

struct CounterMutations: Mutations {
    func commit(action: CounterViewModel.Action, state: CounterViewModel) {
        switch action {
        case .increment:
            state.count.value += 1
            
        case .decrement:
            state.count.value -= 1
        }
    }
}
