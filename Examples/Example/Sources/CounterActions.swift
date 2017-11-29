import Foundation
import VueFlux

enum CounterAction {
    case increment
    case decrement
    case reset
    case update(interval: TimeInterval)
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
    
    func resetAcync(after interval: TimeInterval = 0) {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .reset)
        }
    }
    
    func update(interval: TimeInterval) {
        dispatch(action: .update(interval: interval))
    }
}
