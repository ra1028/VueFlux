import Foundation
import VueFlux
import VueFluxReactive

extension Computed where State == CounterState {
    var countText: Immutable<String?> {
        return state.count.map { String($0) }
    }
    
    var interval: TimeInterval {
        return state.interval.value
    }
    
    var intervalText: Immutable<String?> {
        return state.interval.map { "Count after: \(($0 * 10).rounded() / 10)" }
    }
}

final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let max: Int
    fileprivate let count = Mutable(value: 0)
    fileprivate let interval = Mutable<TimeInterval>(value: 0)
    
    init(max: Int) {
        self.max = max
    }
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .increment:
            state.count.value = min(state.count.value + 1, state.max)

        case .decrement:
            state.count.value = max(state.count.value - 1, 0)
            
        case .reset:
            state.count.value = 0
            
        case let .update(interval):
            state.interval.value = interval
        }
    }
}
