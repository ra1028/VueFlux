import UIKit

public final class CounterView: UIView {
    @IBOutlet public private(set) weak var counterLabel: UILabel!
    @IBOutlet public private(set) weak var intervalLabel: UILabel!
    @IBOutlet public private(set) weak var intervalSlider: UISlider!
    @IBOutlet public private(set) weak var contentView: UIView!
    @IBOutlet public private(set) weak var incrementButton: UIButton!
    @IBOutlet public private(set) weak var decrementButton: UIButton!
    @IBOutlet public private(set) weak var resetButton: UIButton!
    @IBOutlet public private(set) weak var openGitHubButton: UIButton!
    
    @IBInspectable public var startColor: UIColor? {
        didSet { updateColors() }
    }
    
    @IBInspectable public var endColor: UIColor? {
        didSet { updateColors() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override public static var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    var gradientLayer: CAGradientLayer? {
        return layer as? CAGradientLayer
    }
}

private extension CounterView {
    func configure() {
        let nib = UINib(nibName: .init(describing: type(of: self)), bundle: .init(for: type(of: self)))
        guard let view = nib.instantiate(withOwner: self).first as? UIView else { return }
        
        addSubview(view)
        topAnchor.constraint(equalTo: view.topAnchor)
        bottomAnchor.constraint(equalTo: view.bottomAnchor)
        leadingAnchor.constraint(equalTo: view.leadingAnchor)
        trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
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
        round(view: openGitHubButton, corners: [.topLeft, .bottomLeft])
        
        openGitHubButton.titleLabel?.numberOfLines = 2
        
        counterLabel.font = .monospacedDigitSystemFont(ofSize: 80, weight: .thin)
        intervalLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .light)
    }
    
    func updateColors() {
        guard let gradientLayer = gradientLayer else { return }
        
        gradientLayer.colors = [startColor, endColor].flatMap { $0?.cgColor }
        gradientLayer.startPoint = .init(x: 0.5, y: 0)
        gradientLayer.endPoint = .init(x: 0.5, y: 1)
    }
}
