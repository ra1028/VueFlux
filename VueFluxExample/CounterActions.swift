import Foundation
import VueFlux
import RxSwift

enum CounterAction {
    case increment
    case decrement
}

extension Actions where Action == CounterAction {
    func increment(after interval: TimeInterval = 0) -> Disposable {
        return SerialDispatchQueueScheduler(qos: .default).scheduleRelative((), dueTime: interval) {
            self.dispatch(action: .increment)
            return Disposables.create()
        }
    }
    
    func decrement(after interval: TimeInterval = 0) -> Disposable {
        return SerialDispatchQueueScheduler(qos: .default).scheduleRelative((), dueTime: interval) {
            self.dispatch(action: .decrement)
            return Disposables.create()
        }
    }
}
