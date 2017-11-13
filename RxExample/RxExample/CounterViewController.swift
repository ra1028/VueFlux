import UIKit
import VueFlux
import RxSwift
import RxCocoa

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterView: CounterView!
    
    private let store = Store<CounterState>(state: .init(max: 1000), mutations: .init(), executor: .queue(.global()))
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension CounterViewController {
    func configure() {
        let interval = BehaviorRelay<TimeInterval>(value: 0)
        
        counterView.intervalSlider.rx.value
            .map(TimeInterval.init(_:))
            .subscribe(onNext: interval.accept(_:))
            .disposed(by: disposeBag)
        
        interval
            .map { "Count after: \(round($0 * 10) / 10)" }
            .bind(to: counterView.intervalLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.computed.count
            .map(String.init(_:))
            .bind(to: counterView.counterLabel.rx.text)
            .disposed(by: disposeBag)
        
        counterView.incrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.incrementAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
        
        counterView.decrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.decrementAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
        
        counterView.resetButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.resetAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
    }
}
