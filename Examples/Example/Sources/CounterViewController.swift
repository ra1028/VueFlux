import UIKit
import VueFlux
import GenericComponents

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterView: CounterView!
    
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
        
        store.computed.count.bind(to: counterView, \.count)
    }
    
    @objc func increment(_ button: UIButton) {
        store.actions.incrementAcync(after: counterView.interval)
    }
    
    @objc func decrement(_ button: UIButton) {
        store.actions.decrementAcync(after: counterView.interval)
    }
    
    @objc func reset(_ button: UIButton) {
        store.actions.resetAcync(after: counterView.interval)
    }
}
