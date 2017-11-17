import UIKit
import VueFlux
import GenericComponents

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterView: CounterView!
    private var interval: TimeInterval = 0
    
    private let store = Store<CounterState>(state: .init(max: 1000), mutations: .init(), executor: .queue(.global()))
    
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
        counterView.incrementButton.addTarget(self, action: #selector(increment(_:)), for: .touchUpInside)
        counterView.decrementButton.addTarget(self, action: #selector(decrement(_:)), for: .touchUpInside)
        counterView.resetButton.addTarget(self, action: #selector(reset(_:)), for: .touchUpInside)
        counterView.intervalSlider.addTarget(self, action: #selector(updateInterval(_:)), for: .valueChanged)
        
        store.subscribe(scope: self) { [unowned self] action, store in
            switch action {
            case .increment, .decrement, .reset:
                self.counterView.counterLabel.text = .init(store.computed.count)
            }
        }
        
        store.actions.resetAcync()
    }
    
    @objc func increment(_ button: UIButton) {
        store.actions.incrementAcync(after: interval)
    }
    
    @objc func decrement(_ button: UIButton) {
        store.actions.decrementAcync(after: interval)
    }
    
    @objc func reset(_ button: UIButton) {
        store.actions.resetAcync(after: interval)
    }
    
    @objc func updateInterval(_ slider: UISlider) {
        interval = .init(slider.value)
        counterView.intervalLabel.text = "Count after: \(round(interval * 10) / 10)"
    }
}
