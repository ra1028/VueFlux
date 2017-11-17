import VueFlux

extension Computed where State == CounterState {
    var count: Int {
        return state.count
    }
}

final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let max: Int
    fileprivate var count = 0
    
    init(max: Int) {
        self.max = max
    }
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .increment:
            state.count = min(state.count + 1, state.max)

        case .decrement:
            state.count = max(state.count - 1, 0)
            
        case .reset:
            state.count = 0
        }
    }
}
