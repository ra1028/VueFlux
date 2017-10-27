import UIKit
import VueFlux
import RxSwift
import RxCocoa

final class CounterViewController: UIViewController {
    @IBOutlet private weak var incrementButton: UIButton!
    @IBOutlet private weak var decrementButton: UIButton!
    @IBOutlet private weak var stepper: UIStepper!
    @IBOutlet private weak var intervalLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!
    
    private let store = Store<CounterViewModel>(state: .init(), mutations: .init())
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension CounterViewController {
    func configure() {
        let interval = BehaviorRelay<Double>(value: 0)
        let countDisposable = SerialDisposable()
        countDisposable.disposed(by: disposeBag)
        
        stepper.rx.value
            .subscribe(onNext: interval.accept(_:))
            .disposed(by: disposeBag)
        
        interval
            .map { "Count after: \(round($0 * 10) / 10)" }
            .bind(to: intervalLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.expose.count
            .map(String.init(_:))
            .bind(to: countLabel.rx.text)
            .disposed(by: disposeBag)
            
        incrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                countDisposable.disposable = self.store.actions.increment(after: interval.value)
            })
            .disposed(by: disposeBag)
        
        decrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                countDisposable.disposable = self.store.actions.decrement(after: interval.value)
            })
            .disposed(by: disposeBag)
    }
}
