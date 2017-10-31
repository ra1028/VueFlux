import VueFlux
import RxSwift
import RxCocoa

extension Computed where State == CounterState {
    var count: Observable<Int> {
        return state.count.asObservable()
    }
}

final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let count = BehaviorRelay(value: 0)
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .increment:
            state.count.accept(state.count.value + 1)

        case .decrement:
            state.count.accept(state.count.value - 1)
        }
    }
}
