import VueFlux
import RxSwift
import RxCocoa

extension Expose where State == CounterViewModel {
    var count: Observable<Int> {
        return state.count.asObservable()
    }
}

final class CounterViewModel: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let count = BehaviorRelay(value: 0)
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterViewModel) {
        switch action {
        case .increment:
            state.count.accept(state.count.value + 1)

        case .decrement:
            state.count.accept(state.count.value - 1)
        }
    }
}
