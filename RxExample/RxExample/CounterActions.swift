import Foundation
import VueFlux
import RxSwift

enum CounterAction {
    case excute
    case increment
    case decrement
    case reset
}

extension Actions where State == CounterState {
    func incrementAcync(after interval: TimeInterval = 0) {
        dispatch(action: .excute)
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .increment)
        }
    }
    
    func decrementAcync(after interval: TimeInterval = 0) {
        dispatch(action: .excute)
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .decrement)
        }
    }
    
    func resetAcync(after interval: TimeInterval = 0) {
        dispatch(action: .excute)
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + interval) {
            self.dispatch(action: .reset)
        }
    }
}
