import UIKit
import MapKit
import Contentful

protocol NavigatorPresenter {
	func setAnimationState(_ state: NavigatorPresentationAnimator.AnimationState) -> Void
	func updateNavigatorButton() -> Void
}

class BoardViewController: UIViewController, GameStateManagerDelegate, NavigatorPresenter {
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 16
		static let navigatorButtonVerticalCorrection: CGFloat = 8
		static let cameraDistanceForUserLocation: Double = 1_000
		static let cameraZoomRangeMinDistance: Double = 500
		static let cameraZoomRangeMaxDistance: Double = 10000
	}

	private lazy var topHubViewLayout = HubViewBlueprint(
		centerViewLayout: .normal,
		centerViewTopElement: .title(GameStateManager.shared.currentStory?.title ?? ""),
		centerViewBottomElement: .storyProgress(GameStateManager.shared.currentStory?.numberOfCompletedPortals ?? 0,
												GameStateManager.shared.currentStory?.portals?.count ?? 0),
		topLeftButtonStyle: .tourSelection,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .collection,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: presentTourSelection,
		bottomLeftButtonAction: {},
		topRightButtonAction: presentCollection,
		bottomRightButtonAction: {}
	)
	private lazy var bottomHubViewLayout = HubViewBlueprint(
		centerViewLayout: .hidden,
		centerViewTopElement: nil,
		centerViewBottomElement: nil,
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .currentLocation,
		bottomRightButtonStyle: .boardOverview(GameStateManager.shared.currentStory?.isBoardEmpty ?? true),
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: zoomToUserLocation,
		bottomRightButtonAction: zoomToPortals
	)

	private var splashViewTemplate: UIView {
		let splashView = UIView()
		splashView.backgroundColor = .dark90Branded
		
		let appTitleImage = UIImage(named: "splash_screen_logo")
		let appTitleImageView = UIImageView(image: appTitleImage)
		splashView.add(appTitleImageView, activate: [
			appTitleImageView.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
			appTitleImageView.centerYAnchor.constraint(equalTo: splashView.centerYAnchor, constant: -50),
			appTitleImageView.widthAnchor.constraint(equalToConstant: appTitleImage?.size.width ?? 0),
			appTitleImageView.heightAnchor.constraint(equalToConstant: appTitleImage?.size.height ?? 0)
		])
		let activityIndicator = UIActivityIndicatorView.init(style: .large)
		activityIndicator.color = .champagneBranded
		splashView.add(activityIndicator, activate: [
			activityIndicator.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: appTitleImageView.bottomAnchor, constant: 100)
		])
		activityIndicator.startAnimating()
		
		return splashView
	}
	private var splashView: UIView?

	// Local variables
	private let mapView = PharusMapView(mode: .board)
	private lazy var topHubView = HubView(blueprint: topHubViewLayout)
	private lazy var bottomHubView = HubView(blueprint: bottomHubViewLayout)
	private lazy var navigatorButton = NavigatorButton(GameStateManager.shared.currentTool, navigationAction: presentNavigator, collectionAction: presentCollection)
	public lazy var dimView: UIPassThroughView = {
		let view = UIPassThroughView()
		view.backgroundColor = .black
		view.alpha = 0
		return view
	}()

	private var portalAnnotations = [MKAnnotation]()

	private var navigationPresenterAnimationConstraints = [[NavigatorPresentationAnimator.AnimationState: NSLayoutConstraint]]()

	init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		print("BoardVC: Deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		GameStateManager.shared.gameStateManagerDelegate = self

		ContentfulDataManager.shared.finishedFetchingResourcesFollowUps.append {
			
			#if DEBUG
			self.developerReset()
			#endif
			
			self.updateNavigatorButton()
			self.updateContent()
			
			if let currentStory = GameStateManager.shared.currentStory, let lastSelectedAt = currentStory.lastSelectedAt {
				print("»\(currentStory.title ?? "---")« last selected: \(lastSelectedAt)")
				for (i, portal) in (currentStory.portals ?? []).enumerated() {
					print("Portal #\(i+1): »\(portal.title ?? "---")«")
				}
			}
			
			self.initializeViewControllers()
			
		}

		let navigatorButtonVerticalConstraintInitial = navigatorButton.centerYAnchor.constraint(equalTo: bottomHubView.centerYAnchor, constant: Constants.navigatorButtonVerticalCorrection)
		navigationPresenterAnimationConstraints.append([
			.initial: navigatorButtonVerticalConstraintInitial,
			.intermediate: navigatorButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -NavigatorViewController.Constants.offCenterCorrection),
			.final: navigatorButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -NavigatorViewController.Constants.offCenterCorrection),
		])
		let navigatorButtonWidthConstraintInitial = navigatorButton.widthAnchor.constraint(equalToConstant: NavigatorViewController.Constants.toolDiameterSmall)
		let navigatorButtonWidthConstraintFinal = navigatorButton.widthAnchor.constraint(equalToConstant: NavigatorViewController.Constants.toolDiameterLarge)
		navigationPresenterAnimationConstraints.append([
			.initial: navigatorButtonWidthConstraintInitial,
			.intermediate: navigatorButtonWidthConstraintFinal,
			.final: navigatorButtonWidthConstraintFinal
		])
		let navigatorButtonHeightConstraintInitial = navigatorButton.heightAnchor.constraint(equalToConstant: NavigatorViewController.Constants.toolDiameterSmall)
		let navigatorButtonHeightConstraintFinal = navigatorButton.heightAnchor.constraint(equalToConstant: NavigatorViewController.Constants.toolDiameterLarge)
		navigationPresenterAnimationConstraints.append([
			.initial: navigatorButtonHeightConstraintInitial,
			.intermediate: navigatorButtonHeightConstraintFinal,
			.final: navigatorButtonHeightConstraintFinal
		])

		navigatorButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(navigatorButton)
		
		var constraints = [NSLayoutConstraint]()
		
		view.add(mapView, constraints: [
			mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
			mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor)
		], accumulator: &constraints)
		
		view.add(topHubView, constraints: [
			topHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			topHubView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding)
		], accumulator: &constraints)

		view.add(bottomHubView, constraints: [
			bottomHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bottomHubView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottomPadding),
			bottomHubView.widthAnchor.constraint(equalTo: topHubView.widthAnchor)
		], accumulator: &constraints)

		view.add(navigatorButton, constraints: [
			navigatorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			navigatorButtonVerticalConstraintInitial,
			navigatorButtonWidthConstraintInitial,
			navigatorButtonHeightConstraintInitial
		], accumulator: &constraints)

		splashView = splashViewTemplate
		if let splashView = splashView {
			view.add(splashView, accumulator: &constraints)
		}

		view.add(dimView, accumulator: &constraints)
		
		NSLayoutConstraint.activate(constraints)
		
		GameStateManager.shared.syncContentful(viewController: self)
	}

	override var prefersHomeIndicatorAutoHidden: Bool {
		return true
	}
	
	// MARK: - View Controllers on Start Up
	
	private func initializeViewControllers() {
		let tourSelectionVC = TourSelectionViewController(stories: GameStateManager.shared.stories, showCloseButton: false)
		tourSelectionVC.transitioningDelegate = tourSelectionVC.presentationManager
		tourSelectionVC.modalPresentationStyle = .custom

		UIViewController.topMost?.present(tourSelectionVC, animated: true) {
			self.splashView?.removeFromSuperview()
			self.splashView = nil
			if GameStateManager.shared.game?.isIntroCompleted != true {
				let introVC = IntroViewController(mode: .appIntro)
				introVC.modalPresentationStyle = .fullScreen
				tourSelectionVC.present(introVC, animated: false)
			}
		}
	}
	

	// MARK: - Button Actions

	private func presentTourSelection() {
		let tourSelectionVC = TourSelectionViewController(stories: GameStateManager.shared.stories)
		tourSelectionVC.transitioningDelegate = tourSelectionVC.presentationManager
		tourSelectionVC.modalPresentationStyle = .custom
		present(tourSelectionVC, animated: true, completion: nil)
	}

	private func presentCollection() {
		guard let story = GameStateManager.shared.currentStory else { return }

		let collectionVC = CollectionViewController(story: story)
//		collectionVC.modalPresentationStyle = .fullScreen
		collectionVC.modalPresentationStyle = .custom
		collectionVC.transitioningDelegate = collectionVC.presentationManager
		present(collectionVC, animated: true, completion: nil)
	}

	private func zoomToUserLocation() {
		guard let currentLocation = LocationUpdateManager.shared.location else { return }
		let mapCamera = MKMapCamera(lookingAtCenter: currentLocation.coordinate, fromDistance: Constants.cameraDistanceForUserLocation, pitch: 80, heading: 0)
		mapView.setCamera(mapCamera, animated: true)
	}

	private func zoomToPortals() {
		guard let region = allPortalsRegion else { return }

		let (latitudeDelta, longitudeDelta) = region.spanInMeters
		let distance = max(latitudeDelta * 1.8, longitudeDelta * 3.2)
		debugPrint("region.span: \(region.span)")
		debugPrint("region.spanInMeters: \(region.spanInMeters)")
		debugPrint("Distance: \(distance.friendlyString())m")

		let mapCamera = MKMapCamera(lookingAtCenter: region.center, fromDistance: distance, pitch: 80, heading: 0)
		mapView.setCamera(mapCamera, animated: true)
	}

	private var allPortalsRegion: MKCoordinateRegion? {
		guard
			let coordinates = GameStateManager.shared.currentStory?.visiblePortals.compactMap({ $0.location }).map({ $0.coordinate }),
			let minLatitude = coordinates.map({ $0.latitude }).min(),
			let maxLatitude = coordinates.map({ $0.latitude }).max(),
			let minLongitude = coordinates.map({ $0.longitude }).min(),
			let maxLongitude = coordinates.map({ $0.longitude }).max()
		else { return nil }

		return CLLocationCoordinate2D(latitude: minLatitude, longitude: minLongitude).coordinateRegion(spanningTo: CLLocationCoordinate2D(latitude: maxLatitude, longitude: maxLongitude))
	}
	
	// MARK: -
	
	private func presentNavigator() {
		print("Current story exists: \(GameStateManager.shared.currentStory != nil)")
		print("Current portal: \(GameStateManager.shared.currentPortal?.title ?? "---")")
		print("Current tool exists: \(GameStateManager.shared.currentTool != nil)")

		guard
			let currentTool = GameStateManager.shared.currentTool,
			let currentPortal = GameStateManager.shared.currentPortal
		else {
			print("ERROR: Attempted to present navigator without existing current tool")
			return
		}

		dismissIntroNavigationTool()

		let navigatorVC = NavigatorViewController(navigationTool: currentTool, targetPortal: currentPortal)
		navigatorVC.transitioningDelegate = navigatorVC.presentationManager
		navigatorVC.modalPresentationStyle = .custom
		present(navigatorVC, animated: true, completion: nil)
	}

	// MARK: Update Data Helpers
  
	private func updateStoryProgress() {
		guard
			let story = GameStateManager.shared.currentStory,
			let portals = story.portals
			else { return }
		topHubView.updateContent(elementType: .storyProgress(story.numberOfCompletedPortals, portals.count))
	}

	internal func updateContent() {
		guard let story = GameStateManager.shared.currentStory else { return }

		DispatchQueue.main.async {
			self.updateNavigatorButton()
			
			self.topHubView.updateContent(elementType: .title(story.title ?? ""))
			self.updateStoryProgress()

			// Remove all existing overlays and annotations, except the pharus-map
			for overlay in self.mapView.updateableOverlays {
				self.mapView.removeOverlay(overlay)
			}
			self.mapView.removeAnnotations(self.mapView.annotations)

			// Add polyline connecting all portals
			var orderedCoordinates = [CLLocationCoordinate2D]()
			for portal in story.visiblePortals {
				guard let coordinate = portal.location?.coordinate else { continue }
				orderedCoordinates.append(coordinate)
			}
			for pathType: PharusPathLine.LineType in [.outline, .center] {
				let overlay: PharusPathLine = PharusPathLine(coordinates: orderedCoordinates, count: orderedCoordinates.count)
				overlay.type = pathType
				self.mapView.addOverlay(overlay)
			}

			// Add PortalOverlay for each portal on the map
			for portal in story.visiblePortals {
				let portalMapOverlay = PortalMapOverlay(portal: portal)
				self.mapView.addOverlay(portalMapOverlay)

				let annotation = PortalAnnotation(portal: portal)
				self.portalAnnotations.append(annotation)
				self.mapView.addAnnotation(annotation)
			}

			// Update the map
			if story.visiblePortals.count > 0 {
				self.zoomToPortals()
			}
			else {
				self.zoomToUserLocation()
			}
			
			// Board Intro
			if GameStateManager.shared.game?.isBoardIntroCompleted == false {
				DispatchQueue.main.async { self.presentIntroCurrentLocation() }
			}
		}
	}

	// MARK: Intro
	var introTooltipCurrentLocation: IntroTooltip?
	var introTooltipNavigationTool: IntroTooltip?

	private func presentIntroCurrentLocation() {
		introTooltipCurrentLocation?.removeFromSuperview()
		let introTooltip = IntroTooltip(bodyText: IntroTooltip.Constants.bodyTextCurrentLocation, button: DialogueCard.DialogueButton(title: "Weiter", action: { [weak self] in
			self?.presentIntroNavigationTool()
		}))

		introTooltip.alpha = 0
		view.add(introTooltip, activate: [
			introTooltip.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			introTooltip.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -10)
		])
		UIView.animate(withDuration: 0.4) {
			introTooltip.alpha = 1
		}
		
		introTooltipCurrentLocation = introTooltip
		
		self.mapView.touchesBeganAction = { [weak self] in
			self?.presentIntroNavigationTool()
		}
		
	}

	private func presentIntroNavigationTool() {
		mapView.touchesBeganAction = nil
		introTooltipNavigationTool?.removeFromSuperview()
		let introTooltip = IntroTooltip(bodyText: IntroTooltip.Constants.bodyTextNavigationTool)
		introTooltip.alpha = 0
		view.add(introTooltip, activate: [
			introTooltip.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			introTooltip.bottomAnchor.constraint(equalTo: navigatorButton.topAnchor, constant: -10)
		])
		
		print("introTooltipCurrentLocation exists: \(introTooltipCurrentLocation != nil)")
		UIView.animate(withDuration: 0.4, animations: {
			self.introTooltipCurrentLocation?.alpha = 0
			introTooltip.alpha = 1
		}) { (_) in
			self.introTooltipCurrentLocation = nil
		}
		introTooltipNavigationTool = introTooltip
	}

	private func dismissIntroNavigationTool() {
		guard introTooltipNavigationTool != nil else { return }

		UIView.animate(withDuration: 0.4, animations: {
			self.introTooltipNavigationTool?.alpha = 0
		}) { (_) in
			self.introTooltipNavigationTool = nil
			GameStateManager.shared.game?.didCompleteBoardIntro()
		}
	}
	
	// MARK: NavigatorPresenter

	public func setAnimationState(_ state: NavigatorPresentationAnimator.AnimationState) {
		NavigatorPresentationAnimator.activate(constraints: navigationPresenterAnimationConstraints, state: state)
		view.layoutIfNeeded()
	}

	public func updateNavigatorButton() {
		navigatorButton.update(GameStateManager.shared.currentTool)
  }
	
	// MARK: - Developer
	
	private func developerReset() {
		enum Reset {
			case none, storyEnd, regularPortals, lastPortals(count: Int), completeStory, completeGame
			case intros([Game.Intro])
			case solvedStory, solvedGame
		}
		
		// This should be kept at .none
		let reset: Reset = .none
//		let reset: Reset = .regularPortals
//		let reset: Reset = .lastPortals(count: 5)
//		let reset: Reset = .completeGame
//		let reset: Reset = .intros([.ar, .board, .clueObjectSwipe, .game])
//		let reset: Reset = .solvedStory
		
		switch reset {
		case .none:
			break
		case .storyEnd:
			if let lastPortal = GameStateManager.shared.currentStory?.portals?.last {
				lastPortal.setState(.hidden)
				_ = lastPortal.objects?.map { $0.setState(.hidden) }
			}
		case .regularPortals:
			for portal in GameStateManager.shared.currentStory?.portals ?? [] {
				print("lastCompletePortal: \(portal.title ?? "---")")
				portal.reset()
			}
		
		case .lastPortals(count: let countFromBack):
			let portals = GameStateManager.shared.currentStory?.portals ?? []
			for (index, portal) in portals.enumerated() {
				if index < portals.count - countFromBack { portal.setSolved() }
				else { portal.reset() }
			}
			
		case .completeStory:
			GameStateManager.shared.currentStory?.reset()
			
		case .completeGame:
			GameStateManager.shared.game?.reset()

			
		case .intros(let intros):
			GameStateManager.shared.game?.resetIntros(intros)

		case .solvedStory:
			GameStateManager.shared.currentStory?.setSolved()
			
		case .solvedGame:
			GameStateManager.shared.game?.setSolved()
		}
	}
}
