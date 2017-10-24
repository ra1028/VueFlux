import UIKit
import VueFlux
import ReactiveCocoa
import ReactiveSwift

final class CounterViewController: UIViewController {
    @IBOutlet private weak var incrementButton: UIButton!
    @IBOutlet private weak var decrementButton: UIButton!
    @IBOutlet private weak var stepper: UIStepper!
    @IBOutlet private weak var intervalLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!
    
    private let store = Store<CounterViewModel>(state: .init(), mutations: .init())
    private let countDisposable = ScopedDisposable<SerialDisposable>(.init())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension CounterViewController {
    func configure() {
        let interval = Property(initial: 0, then: stepper.reactive.values)
        intervalLabel.reactive.text <~ interval.map { "Count after: \(round($0 * 10) / 10)" }
        countLabel.reactive.text <~ store.state.reactive.count.map(String.init(_:))
        
        incrementButton.reactive.controlEvents(.touchUpInside)
            .take(duringLifetimeOf: self)
            .observeValues { [unowned self] _ in
                self.countDisposable.inner.inner = self.store.actions.increment(after: interval.value)
        }
        
        decrementButton.reactive.controlEvents(.touchUpInside)
            .take(duringLifetimeOf: self)
            .observeValues { [unowned self] _ in
                self.countDisposable.inner.inner = self.store.actions.decrement(after: interval.value)
        }
    }
}
