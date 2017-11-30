import VueFlux
import RxSwift
import RxCocoa

extension Computed where State == CounterState {
    var countText: Observable<String?> {
        return state.count.map { String($0) }
    }
    
    var interval: TimeInterval {
        return state.interval.value
    }
    
    var intervalText: Observable<String?> {
        return state.interval.map { "Count after: \(($0 * 10).rounded() / 10)" }
    }
}

final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let max: Int
    fileprivate let count = BehaviorRelay(value: 0)
    fileprivate let interval = BehaviorRelay<TimeInterval>(value: 0)
    
    init(max: Int) {
        self.max = max
    }
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .increment:
            state.count.accept(min(state.max, state.count.value + 1))

        case .decrement:
            state.count.accept(max(0, state.count.value - 1))
            
        case .reset:
            state.count.accept(0)
            
        case let .update(interval):
            state.interval.accept(interval)
        }
    }
}
