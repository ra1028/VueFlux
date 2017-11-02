import UIKit
import VueFlux
import RxSwift
import RxCocoa

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var counterShadowView: UIView!
    @IBOutlet private weak var counterContentView: UIView!
    @IBOutlet private weak var shadowView: UIView!
    @IBOutlet private weak var excuteView: UIView!
    
    @IBOutlet private weak var intervalSlider: UISlider!
    @IBOutlet private weak var intervalLabel: UILabel!
    @IBOutlet private weak var intervalContentView: UIView!
    
    @IBOutlet private weak var incrementButton: UIButton!
    @IBOutlet private weak var decrementButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!
    
    private let store = Store<CounterState>(state: .init(max: 100), mutations: .init(), executor: .queue(.global()))
    private let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        configureViews()
    }
}

private extension CounterViewController {
    func bind() {
        let interval = BehaviorRelay<TimeInterval>(value: 0)
        
        intervalSlider.rx.value
            .map(TimeInterval.init(_:))
            .subscribe(onNext: interval.accept(_:))
            .disposed(by: disposeBag)
        
        interval
            .map { "Count after: \(round($0 * 10) / 10)" }
            .bind(to: intervalLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.computed.count
            .map(String.init(_:))
            .bind(to: counterLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.computed.excute
            .observeOn(MainScheduler.instance)
            .do(onNext: { [unowned self] in self.excuteView.isHidden = false })
            .observeOn(ConcurrentDispatchQueueScheduler(queue: .main))
            .map { true }
            .bind(to: excuteView.rx.setHiddenAnimated(duration: 0.5))
            .disposed(by: disposeBag)
        
        incrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.incrementAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
        
        decrementButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.decrementAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
        
        resetButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [unowned self] _ in
                self.store.actions.resetAcync(after: interval.value)
            })
            .disposed(by: disposeBag)
    }
    
    func configureViews() {
        counterLabel.layer.cornerRadius = 15
        counterLabel.layer.borderWidth = 7
        counterLabel.layer.borderColor = view.backgroundColor?.cgColor
        counterShadowView.layer.shadowOffset = .init(width: 0, height: 2)
        counterShadowView.layer.shadowOpacity = 0.3
        counterShadowView.layer.shadowRadius = 2
        counterContentView.layer.cornerRadius = 15
        intervalContentView.layer.cornerRadius = 15
        shadowView.layer.shadowOffset = .init(width: 0, height: 5)
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowRadius = 5
        excuteView.layer.cornerRadius = excuteView.bounds.height / 2
        
        let buttons: [UIButton] = [incrementButton, decrementButton, resetButton]
        buttons.forEach { $0.layer.cornerRadius = 10 }
    }
}

private extension Reactive where Base: UIView {
    func setHiddenAnimated(duration: TimeInterval) -> Binder<Bool> {
        return .init(base) { target, isHidden in
            UIView.transition(
                with: target,
                duration: duration,
                options: [.transitionCrossDissolve, .overrideInheritedDuration],
                animations: { target.isHidden = isHidden }
            )
        }
    }
}
