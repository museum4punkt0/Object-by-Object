import UIKit
import SceneKit
import AVKit

class TourSelectionViewController: UIViewController, PortalSessionPresentationDelegate, UIScrollViewDelegate {
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let toolDiameterSmall: CGFloat = 106
		static let navigatorButtonVerticalCorrection: CGFloat = 64
		static let toolDiameterLarge: CGFloat = 250
		static let offCenterCorrection: CGFloat = 60

	}

	var presentationManager = TourSelectionPresentationManager()
	
	private lazy var topHubView = HubView(blueprint: topHubViewLayout)
	private let scrollView = UIScrollView()
	private lazy var tourSelectionCardsContainer = TourSelectionCardsContainer(tourSelectionCards)
	private var tourSelectionCards = [TourSelectionCard]()

	private lazy var outerMask: UICircleView = {
		let circle = UICircleView()
		circle.backgroundColor = .dark90Branded
		return circle
	}()
	private lazy var outerMaskLayoutView: UIPassThroughView = {
		let view = UIPassThroughView()
		view.backgroundColor = .clear
		return view
	}()

	private lazy var topHubViewLayout = HubViewBlueprint(
		centerViewLayout: .normal,
		centerViewTopElement: .title("Zeitreisen"),
		centerViewBottomElement: .pageIndicator(1, tourSelectionCards.count),
		topLeftButtonStyle: .intro,
		bottomLeftButtonStyle: .about,
		topRightButtonStyle: self.showCloseButton ? .close : .hidden,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: { [weak self] in self?.presentIntro() },
		bottomLeftButtonAction: { [weak self] in self?.presentAbout() },
		topRightButtonAction: self.showCloseButton ? { [weak self] in self?.tapClose() } : {},
		bottomRightButtonAction: {}
	)

	private var circularPresentationConstraints = [[TourSelectionPresentationAnimator.AnimationState: NSLayoutConstraint]]()
	private var slidePresentationConstraints = [[TourSelectionPresentationAnimator.AnimationState: NSLayoutConstraint]]()

	private var showCloseButton: Bool

	// PortalSessionPresentationDelegate
	public var portalSessionHasBeenCompleted: Bool = false

	init(stories: [Story], showCloseButton: Bool = true) {
		self.showCloseButton = showCloseButton
		super.init(nibName: nil, bundle: nil)
		for story in stories {
			tourSelectionCards.append(TourSelectionCard(story, selectAction: { [weak self] in
				guard let self = self else { return }

				GameStateManager.shared.trigger(.selectStory(story))
				if story.state == .notStarted {
					// Start SessionZero
					self.prepareSessionZero(for: story)
				} else {
					self.dismiss(animated: true, completion: nil)
				}
			}))
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("TourSelectionVC: Deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		GameStateManager.shared.portalSessionPresentationDelegate = self

		view.backgroundColor = .clear

		var constraints = [NSLayoutConstraint]()

		let containerView = UIPassThroughView()
		containerView.backgroundColor = .dark90Branded
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)

		scrollView.delegate = self
		scrollView.isPagingEnabled = true
		scrollView.isDirectionalLockEnabled = true
		scrollView.isScrollEnabled = true
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(scrollView)

		tourSelectionCardsContainer.translatesAutoresizingMaskIntoConstraints = false
		scrollView.addSubview(tourSelectionCardsContainer)

		topHubView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(topHubView)

		scrollView.contentSize = CGSize(width: CGFloat(tourSelectionCardsContainer.cardsInTotal) * TourSelectionCard.cardWidth,
		height: TourSelectionCard.cardHeight)

		// Outer Mask
		let outerMaskVerticalConstraintInitial = outerMaskLayoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.navigatorButtonVerticalCorrection)
		circularPresentationConstraints.append([
			.initial: outerMaskVerticalConstraintInitial,
			.intermediate: outerMaskLayoutView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Constants.offCenterCorrection),
			.final: outerMaskLayoutView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		let outerMaskWidthConstraintInitial = outerMaskLayoutView.widthAnchor.constraint(equalToConstant: Constants.toolDiameterSmall)
		circularPresentationConstraints.append([
			.initial: outerMaskWidthConstraintInitial,
			.intermediate: outerMaskLayoutView.widthAnchor.constraint(equalToConstant: Constants.toolDiameterLarge),
			.final: outerMaskLayoutView.widthAnchor.constraint(equalToConstant: sqrt(pow(view.frame.size.width, 2) + pow(view.frame.size.height, 2)))
		])

		let outerMaskHeightConstraintInitial = outerMaskLayoutView.heightAnchor.constraint(equalToConstant: Constants.toolDiameterSmall)
		circularPresentationConstraints.append([
			.initial: outerMaskHeightConstraintInitial,
			.intermediate: outerMaskLayoutView.heightAnchor.constraint(equalToConstant: Constants.toolDiameterLarge),
			.final: outerMaskLayoutView.heightAnchor.constraint(equalToConstant: sqrt(pow(view.frame.size.width, 2) + pow(view.frame.size.height, 2)))
		])
		view.add(outerMaskLayoutView, constraints: [
			outerMaskLayoutView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			outerMaskVerticalConstraintInitial,
			outerMaskWidthConstraintInitial,
			outerMaskHeightConstraintInitial
		], accumulator: &constraints)
		view.mask = outerMask

		// ContainerView constraints
		let containerViewTopConstraintInitial = containerView.topAnchor.constraint(equalTo: view.bottomAnchor)
		slidePresentationConstraints.append([
			.initial: containerViewTopConstraintInitial,
			.final: containerView.topAnchor.constraint(equalTo: view.topAnchor)
		])

		let containerViewCenterXConstraint = containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		let containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: view.heightAnchor)
		let containerViewWidthConstraint = containerView.widthAnchor.constraint(equalTo: view.widthAnchor)

		NSLayoutConstraint.activate(constraints)

		NSLayoutConstraint.activate([
			containerViewCenterXConstraint,
			containerViewHeightConstraint,
			containerViewWidthConstraint,
			containerViewTopConstraintInitial,

			scrollView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			scrollView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
			scrollView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: TourSelectionCard.cardHeight*0.05),
			scrollView.heightAnchor.constraint(equalToConstant: TourSelectionCard.cardHeight),

			topHubView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			topHubView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -2 * Constants.horizontalPadding)
		])
		
		var currentStoryIndex = 0
		for (i, story) in GameStateManager.shared.stories.enumerated() {
			if story == GameStateManager.shared.currentStory {
				currentStoryIndex = i
				break
			}
		}
		scrollView.contentOffset.x = UIScreen.main.bounds.width * CGFloat(currentStoryIndex)
		topHubView.updateContent(elementType: .pageIndicator(currentStoryIndex+1, tourSelectionCardsContainer.cardsInTotal))
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		outerMask.frame = outerMaskLayoutView.frame
	}

	// MARK: UIScrollViewDelegate

	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		let pageNumber = Int(scrollView.contentOffset.x / TourSelectionCard.cardWidth) + 1
		let pagesInTotal = tourSelectionCardsContainer.cardsInTotal
		topHubView.updateContent(elementType: .pageIndicator(pageNumber, pagesInTotal))
	}

	// MARK: Interaction Handlers

	private func presentAbout() {
		let aboutVC = AboutViewController()
		aboutVC.modalPresentationStyle = .fullScreen
		present(aboutVC, animated: true, completion: nil)
	}

	private func presentIntro() {
		let introVC = IntroViewController(mode: .completeIntro)
		introVC.modalPresentationStyle = .fullScreen
		present(introVC, animated: true, completion: nil)
	}

	private func tapClose() {
		dismiss(animated: true, completion: nil)
	}

	private func prepareSessionZero(for story: Story) {
		UIView.animate(withDuration: 0.2, animations: {
			self.topHubView.alpha = 0
			self.scrollView.alpha = 0
		}) { (_) in
			if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
				//already authorized
				if GameStateManager.shared.game?.isARIntroCompleted == true {
					self.launchSessionZero(for: story)
				}
				else {
					self.presentARIntro(story: story)
				}
			} else {
				
//				let arInstructionCard = DialogueCard(style: .custom(Constants.helpWithClueObjectCardTitle, Constants.helpWithClueObjectCardBody, [
//					DialogueCard.DialogueButton(title: "Weiterrätseln", action: {}),
//					DialogueCard.DialogueButton(title: "Einfacheres Artefakt", action: { [weak self] in
//						self?.downgradeNavigationObject()
//					})
//				]))
				
				AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
					DispatchQueue.main.async {
						if granted {
							//access allowed
							if GameStateManager.shared.game?.isARIntroCompleted == true {
								self.launchSessionZero(for: story)
							} else {
								self.presentARIntro(story: story)
							}
						} else {
							//access denied
							let missingCameraPermissionAlert = UIAlertController(title: "Kamerazugriff", message: "Die App benötigt Kamerazugriff für Augmented Reality.", preferredStyle: .alert)
							missingCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
								if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
									UIApplication.shared.open(settingsURL, options: [:])
								}
								self.fadeIn()
							}))
							self.present(missingCameraPermissionAlert, animated: true)
						}
					}
				})
			}
		}
	}
	
	private func presentARIntro(story: Story) {
		let introVC = IntroViewController(mode: .arIntro, afterDismiss: { [weak self] in
			self?.launchSessionZero(for: story)
		})
		introVC.modalPresentationStyle = .fullScreen
		present(introVC, animated: false)
	}
	
	private func launchSessionZero(for story: Story) {
		let portalSessionVC = PortalSessionViewController(from: story)
		self.add(portalSessionVC)

		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
			portalSessionVC.updateOuterMask()
			UIView.animate(withDuration: 1.0, animations: {
				portalSessionVC.updateOuterMask()
				portalSessionVC.openShutterHalf()
			}) { (_) in
				UIView.animate(withDuration: 1.0) {
					portalSessionVC.fadeInCameraView()
				}
			}
		})
	}

	public func fadeIn() {
		UIView.animate(withDuration: 0.2, animations: {
			self.topHubView.alpha = 1.0
			self.scrollView.alpha = 1.0
		})
	}
}


extension TourSelectionViewController {
	public func setCircularAnimationState(_ state: TourSelectionPresentationAnimator.AnimationState) {
		TourSelectionPresentationAnimator.activate(constraints: circularPresentationConstraints, state: state)
		TourSelectionPresentationAnimator.activate(constraints: slidePresentationConstraints, state: .final)

		view.layoutIfNeeded()
		outerMask.frame = outerMaskLayoutView.frame
		outerMask.layer.cornerRadius = outerMask.frame.size.width/2
	}

	public func setSlideAnimationState(_ state: TourSelectionPresentationAnimator.AnimationState) {
		TourSelectionPresentationAnimator.activate(constraints: slidePresentationConstraints, state: state)
		TourSelectionPresentationAnimator.activate(constraints: circularPresentationConstraints, state: .final)

		view.layoutIfNeeded()
		outerMask.frame = outerMaskLayoutView.frame
	}
}

class TourSelectionPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		return nil
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		 return TourSelectionPresentationAnimator(direction: .to, portalSessionCompleted: false)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		// Only display the circular dismiss animation when the navigator tool has been successfully collected in session zero
		guard let tourSelectionVC = dismissed as? TourSelectionViewController else { return nil }

		return TourSelectionPresentationAnimator(direction: .from, portalSessionCompleted: tourSelectionVC.portalSessionHasBeenCompleted)
    }
}

final class TourSelectionPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	enum AnimationState {
		case initial
		case intermediate
		case final
	}

	static public func activate(constraints: [[AnimationState: NSLayoutConstraint]], state activeState: AnimationState) {
		for constraintsDict in constraints {
			NSLayoutConstraint.deactivate(Array(constraintsDict.filter({ $0.0 != activeState }).values))
			NSLayoutConstraint.activate(constraintsDict.filter({ $0.0 == activeState }).map({ $0.1 }))
		}
	}

    let direction: UITransitionContextViewControllerKey
	private let portalSessionCompleted: Bool

    init(direction: UITransitionContextViewControllerKey, portalSessionCompleted: Bool) {
        self.direction = direction
		self.portalSessionCompleted = portalSessionCompleted
        super.init()
    }

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.8
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let presenting = direction == .to
		guard
			let tourSelectionVC = transitionContext.viewController(forKey: direction) as? TourSelectionViewController,
			let boardVC = transitionContext.viewController(forKey: presenting ? .from : .to) as? BoardViewController
		else { return }

		transitionContext.containerView.addSubview(tourSelectionVC.view)

		if !presenting { boardVC.updateNavigatorButton() }

		if portalSessionCompleted {
			let initialAlpha: CGFloat = presenting ? 0 : 1
			let finalAlpha: CGFloat = presenting ? 1 : 0

			tourSelectionVC.view.alpha = initialAlpha
			tourSelectionVC.setCircularAnimationState(presenting ? .initial : .final)
			boardVC.setAnimationState(presenting ? .initial : .final)

			UIView.animate(withDuration: transitionDuration(using: transitionContext)/2, delay: 0, animations: {
				if presenting { tourSelectionVC.view.alpha = finalAlpha }
				tourSelectionVC.setCircularAnimationState(.intermediate)
				boardVC.setAnimationState(.intermediate)
			}) { (_) in
				UIView.animate(withDuration: self.transitionDuration(using: transitionContext)/2, delay: 0, animations: {
					if !presenting { tourSelectionVC.view.alpha = finalAlpha }
					tourSelectionVC.setCircularAnimationState(presenting ? .final : .initial)
					boardVC.setAnimationState(presenting ? .final : .initial)
				}) { finished in
					transitionContext.completeTransition(finished)
				}
			}
		} else {
			tourSelectionVC.setSlideAnimationState(presenting ? .initial : .final)

			UIView.animate(withDuration: 0.4, delay: 0, animations: {
				tourSelectionVC.setSlideAnimationState((presenting ? .final : .initial))
				tourSelectionVC.view.layoutIfNeeded()
			}) { finished in
				transitionContext.completeTransition(finished)
			}
		}
	}
}
