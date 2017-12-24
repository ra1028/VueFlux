import UIKit
import VueFlux
import VueFluxReactive
import GenericComponents

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterView: CounterView!
    
    private let store = Store<CounterState>(state: .init(max: 1000), mutations: .init(), executor: .immediate)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension CounterViewController {
    func configure() {
        counterView.incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)
        counterView.decrementButton.addTarget(self, action: #selector(decrement), for: .touchUpInside)
        counterView.resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        counterView.intervalSlider.addTarget(self, action: #selector(updateInterval(_:)), for: .valueChanged)
        
        store.computed.countText
            .observe(on: .mainThread)
            .bind(to: counterView.counterLabel, \.text)
        
        store.computed.intervalText
            .observe(on: .mainThread)
            .bind(to: counterView.intervalLabel, \.text)
    }
    
    @objc func increment() {
        store.actions.incrementAcync(after: store.computed.interval)
    }
    
    @objc func decrement() {
        store.actions.decrementAcync(after: store.computed.interval)
    }
    
    @objc func reset() {
        store.actions.resetAcync(after: store.computed.interval)
    }
    
    @objc func updateInterval(_ slider: UISlider) {
        store.actions.update(interval: TimeInterval(slider.value))
    }
}
