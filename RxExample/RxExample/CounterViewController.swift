import UIKit
import VueFlux
import RxSwift
import RxCocoa

final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var intervalLabel: UILabel!
    @IBOutlet private weak var intervalSlider: UISlider!
    @IBOutlet private weak var incrementButton: UIButton!
    @IBOutlet private weak var decrementButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!
    
    private let store = Store<CounterState>(state: .init(max: 1000), mutations: .init(), executor: .queue(.global()))
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
        func round(view: UIView, corners: UIRectCorner) {
            let path = UIBezierPath(
                roundedRect: view.bounds,
                byRoundingCorners: corners,
                cornerRadii: .init(width: view.bounds.width, height: view.bounds.height)
            )
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask
        }
        
        round(view: incrementButton, corners: [.topRight, .bottomRight])
        round(view: decrementButton, corners: [.topRight, .bottomRight])
        round(view: resetButton, corners: [.topLeft, .bottomLeft])
    }
}

final class GradientView: UIView {
    @IBInspectable var startColor: UIColor? {
        didSet {
            guard startColor != oldValue else { return }
            configure()
        }
    }
    
    @IBInspectable var endColor: UIColor? {
        didSet {
            guard endColor != oldValue else { return }
            configure()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    override static var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    var gradientLayer: CAGradientLayer? {
        return layer as? CAGradientLayer
    }
}

private extension GradientView {
    func configure() {
        guard let gradientLayer = gradientLayer else { return }
        
        gradientLayer.colors = [startColor, endColor].flatMap { $0?.cgColor }
        gradientLayer.startPoint = .init(x: 0.5, y: 0)
        gradientLayer.endPoint = .init(x: 0.5, y: 1)
    }
}
