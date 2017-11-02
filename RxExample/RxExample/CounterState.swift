import VueFlux
import RxSwift
import RxCocoa

extension Computed where State == CounterState {
    var excute: Observable<Void> {
        return state.excute.asObservable()
    }
    
    var count: Observable<Int> {
        return state.count.asObservable()
    }
}

final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations
    
    fileprivate let max: Int
    fileprivate let count = BehaviorRelay(value: 0)
    fileprivate let excute = PublishSubject<()>()
    
    init(max: Int) {
        self.max = max
    }
}

struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .excute:
            state.excute.onNext(())
            
        case .increment:
            state.count.accept(min(state.max, state.count.value + 1))

        case .decrement:
            state.count.accept(max(0, state.count.value - 1))
            
        case .reset:
            state.count.accept(0)
        }
    }
}
