import UIKit
import RxSwift
import RxCocoa

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var touchDisplayWindow: TouchDisplayWidow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        let viewControllerClass = CounterViewController.self
        let storyboard = UIStoryboard(name: .init(describing: viewControllerClass), bundle: .init(for: viewControllerClass))
        let viewController = storyboard.instantiateInitialViewController()
        let touchTrackWindow = TouchTrackWindow(frame: UIScreen.main.bounds)
        touchTrackWindow.rootViewController = viewController
        touchTrackWindow.makeKeyAndVisible()
        self.window = touchTrackWindow
        
        let touchDisplayWindow = TouchDisplayWidow(touches: touchTrackWindow.touches)
        self.touchDisplayWindow = touchDisplayWindow
        return true
    }
}

private final class TouchTrackWindow: UIWindow {
    var touches: Observable<UITouch> {
        return touchRelay.asObservable()
    }
    
    private let touchRelay = PublishRelay<UITouch>()
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        guard let touch = event.allTouches?.first else { return }
        touchRelay.accept(touch)
    }
}

private final class TouchDisplayWidow: UIWindow {
    private let trackView = UIView()
    private let touches: Observable<UITouch>
    private let disposeBag = DisposeBag()
    
    init(touches: Observable<UITouch>) {
        self.touches = touches
        super.init(frame: UIScreen.main.bounds)
        configure()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event).flatMap { $0 == self ? nil : $0 }
    }
}

private extension TouchDisplayWidow {
    func configure() {
        isHidden = false
        backgroundColor = .clear
        windowLevel = UIWindowLevelNormal + 1
        rootViewController = ThroughViewController()
        
        trackView.bounds = .init(x: 0, y: 0, width: 64, height: 64)
        trackView.backgroundColor = .init(white: 1, alpha: 0.4)
        trackView.layer.cornerRadius = trackView.bounds.height / 2
        trackView.isHidden = true
        
        addSubview(trackView)
        
        touches
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] touch in
                self.trackView.center = touch.location(in: self)
                self.trackView.isHidden = touch.phase.isPointHidden
            })
            .disposed(by: disposeBag)
    }
}

private final class ThroughViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func loadView() {
        super.loadView()
        view = ThroughView()
    }
}

private final class ThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event).flatMap { $0 == self ? nil : $0 }
    }
}

private extension UITouchPhase {
    var isPointHidden: Bool {
        return [.ended, .cancelled].contains(self)
    }
}
