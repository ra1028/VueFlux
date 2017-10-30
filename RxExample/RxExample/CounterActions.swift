import Foundation
import VueFlux
import RxSwift

enum CounterAction {
    case increment
    case decrement
}

extension Actions where State == CounterState {
    func incrementAcync(after interval: TimeInterval = 0) {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .increment)
        }
    }
    
    func decrementAcync(after interval: TimeInterval = 0) {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .decrement)
        }
    }
}
