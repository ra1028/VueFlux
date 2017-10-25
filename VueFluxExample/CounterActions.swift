import VueFlux
import ReactiveSwift

enum CounterAction {
    case increment
    case decrement
}

extension Actions where Action == CounterAction {
    func increment(after interval: TimeInterval = 0) -> Disposable? {
        guard interval > 0 else {
            dispatch(action: .increment)
            return nil
        }
        
        return QueueScheduler().schedule(after: .init(timeIntervalSinceNow: interval)) {
            self.dispatch(action: .increment)
        }
    }
    
    func decrement(after interval: TimeInterval = 0) -> Disposable? {
        guard interval > 0 else {
            dispatch(action: .decrement)
            return nil
        }
        
        return QueueScheduler().schedule(after: .init(timeIntervalSinceNow: interval)) {
            self.dispatch(action: .decrement)
        }
    }
}
