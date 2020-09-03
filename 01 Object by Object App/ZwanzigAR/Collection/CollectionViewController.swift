import UIKit
import MapKit
import AVFoundation

class CollectionViewController: UIViewController, NavigatorPresenter {
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = -42
	}

	// Static properties
	static let speechSynthesizer = AVSpeechSynthesizer()

	// Properties
	private let story: Story
	private let startPortal: Portal?

	// Views
	private lazy var topHubView = HubView(blueprint: topHubViewLayout)
	private lazy var bottomHubView = HubView(blueprint: bottomHubViewLayout)
	private lazy var scrollContainerView = CollectionPagesContainerView(story: story,
															   openAt: startPortal,
															   hubView: bottomHubView)
	private var navigationPresenterAnimationConstraints = [[NavigatorPresentationAnimator.AnimationState: NSLayoutConstraint]]()
	
	// Layout
	private lazy var topHubViewLayout = HubViewBlueprint(
		centerViewLayout: .hidden,
		centerViewTopElement: nil,
		centerViewBottomElement: nil,
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .close,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: { [weak self] in
			self?.tapClose() },
		bottomRightButtonAction: {}
	)
	private lazy var bottomHubViewLayout = HubViewBlueprint(
		centerViewLayout: .normal,
		centerViewTopElement: .title("Sammelalbum"),
		centerViewBottomElement: .pageIndicator((startPortal?.numberInStory ?? 0) + 1, story.visiblePortals.count + 2),
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .hidden,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: {},
		bottomRightButtonAction: {}
	)

	public lazy var dimView: UIPassThroughView = {
		let view = UIPassThroughView()
		view.backgroundColor = .black
		view.alpha = 0
		return view
	}()
	
	public var presentationManager = CollectionPresentationManager()
	
	init(story: Story, openAt portal: Portal? = nil) {
		self.story = story
		self.startPortal = portal
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("CollectionVC deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.add(scrollContainerView)

		view.add(topHubView, activate: [
			topHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			topHubView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding)
		])

		view.add(bottomHubView, activate: [
			bottomHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bottomHubView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottomPadding),
			bottomHubView.widthAnchor.constraint(equalTo: topHubView.widthAnchor)
		])
		
		view.add(dimView)
	}

	// MARK: Button Actions

	private func tapClose() {
		dismiss(animated: true, completion: nil)
	}

	// MARK: NavigatorPresenter

	public func setAnimationState(_ state: NavigatorPresentationAnimator.AnimationState) {
		NavigatorPresentationAnimator.activate(constraints: navigationPresenterAnimationConstraints, state: state)
		view.layoutIfNeeded()
	}

	public func updateNavigatorButton() {}
}

class CollectionPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//		let presentationController = DimmedPopupPresentationController(presentedViewController: presented, presenting: presenting)
//		return presentationController
		return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return PageTurnPresentationAnimator(direction: .to)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return PageTurnPresentationAnimator(direction: .from)
    }
}


final class PageTurnPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: UITransitionContextViewControllerKey
    
    init(direction: UITransitionContextViewControllerKey) {
        self.direction = direction
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
			let collectionController = transitionContext.viewController(forKey: direction) as? CollectionViewController,
			let boardController = transitionContext.viewController(forKey: direction == .to ? .from : .to) as? BoardViewController

		else { return }
		
		print("boardController is \(String(describing: boardController.self))")
		
        let presentedFrame = transitionContext.finalFrame(for: collectionController)
        var dismissedFrame = presentedFrame
        
		if direction == .to {
            transitionContext.containerView.addSubview(collectionController.view)
        }
		dismissedFrame.origin.x += 0.75 * (direction == .to ? presentedFrame.width : dismissedFrame.width)
		
		var perspectiveTransform = CATransform3DIdentity
		perspectiveTransform.m34 = 1/1_000
		let rotation: CGFloat = -.pi/2
		let initialRotation = direction == .to ? rotation : 0
		let finalRotation = direction == .to ? 0 : rotation

		let initialDimAlphaBoard: CGFloat = direction == .to ? 0 : 1
		let finalDimAlphaBoard: CGFloat = direction == .to ? 1 : 0
		let initialDimAlphaCollection: CGFloat = direction == .to ? 0.5 : 0
		let finalDimAlphaCollection: CGFloat = direction == .to ? 0 : 0.5

		collectionController.view.setAnchorPoint(CGPoint(x: 1, y: 0.5))
		
		collectionController.view.layer.transform = CATransform3DRotate(perspectiveTransform, initialRotation, 0, 1, 0)
		boardController.dimView.alpha = initialDimAlphaBoard
		collectionController.dimView.alpha = initialDimAlphaCollection
		UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
			collectionController.view.layer.transform = CATransform3DRotate(perspectiveTransform, finalRotation, 0, 1, 0)
			boardController.dimView.alpha = finalDimAlphaBoard
			collectionController.dimView.alpha = finalDimAlphaCollection
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
