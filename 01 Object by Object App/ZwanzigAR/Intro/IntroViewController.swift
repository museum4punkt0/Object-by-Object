import UIKit

class IntroPageViewController: UIViewController {
	struct Constants {
		static let horizontalPadding: CGFloat = 32
		static let verticalPadding: CGFloat = 16
		static let maximumContentWidth: CGFloat = 480
	}

	enum Page: String {
		case appIntro1
		case appIntro2
		case appIntro3
		case appIntro4
		case arIntro1
		case arIntro2

		var headline: String {
			switch self {
			case .appIntro1:
				return "Eine Zeitreise in das Berlin der 20er mit Hilfe von Karten-Ortung und Augmented Reality"
			case .appIntro2:
				return "Verborgene Zeitreise-Portale – mitten in der Stadt"
			case .appIntro3:
				return "Navigations-Artefakte weisen Dir den Weg"
			case .appIntro4:
				return "Unterwegs mit dem Stadtplan Berlins von 1929"
			case .arIntro1:
				return "Wetter- und Lichtverhältnisse"
			case .arIntro2:
				return "Achte auf den Verkehr und deine Mitmenschen!"
			}
		}

		var body: String {
			switch self {
			case .appIntro1:
				return "Begib Dich mit den Berliner Museen auf eine Zeitreise in die legendären 1920er Jahre — mitten im heutigen Berlin!"
			case .appIntro2:
				return "Finde mit Hilfe von Augmented Reality in der Stadt versteckte Zeitreise-Portale und entdecke Geschichten der 1920er an den Originalschauplätzen."
			case .appIntro3:
				return "In den Portalen findest du Navigations-Artefakte, die dir den Weg zum nächsten Portal zeigen."
			case .appIntro4:
				return "Als Orientierung dient der Pharus-Plan, der damalige Marktführer unter den Berliner Stadtplänen."
			case .arIntro1:
				return "Für ein ungetrübtes Augmented-Reality-Erlebnis lässt sich die App am besten bei Tageslicht und trockenen Wetterverhältnissen spielen. Regen, Dunkelheit und kontrastreiche Schlagschatten können das Spielerlebnis beeinträchtigen."
			case .arIntro2:
				return "Das Spiel findet im öffentlichen Raum statt. Achte stets darauf, dass du beim Spielen nicht auf Straßen oder Radwegen oder anderen Menschen im Weg stehst."
			}
		}

		var illustration: UIImage? {
			switch self {
			case .appIntro1:
				return UIImage(named: "illu_willkommen")
			case .appIntro2:
				return UIImage(named: "illu_portals")
			case .appIntro3:
				return UIImage(named: "illu_navigation")
			case .appIntro4:
				return UIImage(named: "illu_pharus")
			case .arIntro1:
				return UIImage(named: "Intro AR 1")
			case .arIntro2:
				return UIImage(named: "Intro AR 2")
			}
		}
		
		var circleColor: UIColor {
			switch self {
			case .appIntro1, .appIntro2, .appIntro3, .appIntro4:
				return .dark60Branded
			default:
				return .clear
			}
		}
	}

	public let page: Page

	init(_ page: Page) {
		self.page = page
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .dark90Branded

		let circleView = UICircleView()
		circleView.backgroundColor = page.circleColor
		circleView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(circleView)

		let illustration = UIImageView(image: page.illustration)
		illustration.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(illustration)

		let headline = UILabel.label(for: .headline2, text: page.headline)
		headline.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(headline)
		let headlineWidthConstraint = headline.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -Constants.horizontalPadding*2)
		headlineWidthConstraint.priority = .defaultHigh
		let headlineMaxWidthConstraint = headline.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maximumContentWidth)
		headlineMaxWidthConstraint.priority = .required

		let body = UILabel.label(for: .body, text: page.body)
		body.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(body)
		let bodyWidthConstraint = body.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -Constants.horizontalPadding*2)
		bodyWidthConstraint.priority = .defaultHigh
		let bodyMaxWidthConstraint = body.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maximumContentWidth)
		bodyMaxWidthConstraint.priority = .required
		
		NSLayoutConstraint.activate([
			circleView.widthAnchor.constraint(equalToConstant: 200),
			circleView.heightAnchor.constraint(equalToConstant: 200),
			circleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			circleView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),

			illustration.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
			illustration.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),

			headline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			headlineWidthConstraint,
			headlineMaxWidthConstraint,

			body.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bodyWidthConstraint,
			bodyMaxWidthConstraint,
			body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: Constants.verticalPadding),
			body.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140)
		])
	}
}

class IntroViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
	enum Mode {
		case appIntro, arIntro, completeIntro
	}
	
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = -42
	}

	private let mode: Mode

	private var displayTitle: String {
		switch mode {
		case .appIntro:
			return "Willkommen"
		case .arIntro:
			return "Wie funktioniert AR?"
		case .completeIntro:
			return "Einführung"
		}
	}
	
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
		topRightButtonAction: { [weak self] in self?.tapClose() },
		bottomRightButtonAction: {}
	)
	private lazy var topHubView = HubView(blueprint: topHubViewLayout)

	private lazy var bottomHubViewLayout = HubViewBlueprint(
		centerViewLayout: .normal,
		centerViewTopElement: .title(self.displayTitle),
		centerViewBottomElement: .pageIndicator(currentIndex+1, allPages.count),
		topLeftButtonStyle: .back,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .next,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: { [weak self] in self?.tapPrevious() },
		bottomLeftButtonAction: {},
		topRightButtonAction: { [weak self] in self?.tapNext() },
		bottomRightButtonAction: {}
	)
	private lazy var bottomHubView = HubView(blueprint: bottomHubViewLayout)

	private var allPages: [IntroPageViewController] {
		switch self.mode {
		case .appIntro:
			return [
				IntroPageViewController(.appIntro1),
				IntroPageViewController(.appIntro2),
				IntroPageViewController(.appIntro3),
				IntroPageViewController(.appIntro4)
			]
		case .arIntro:
			return [
				IntroPageViewController(.arIntro1),
				IntroPageViewController(.arIntro2)
			]
		case .completeIntro:
			return [
				IntroPageViewController(.appIntro1),
				IntroPageViewController(.appIntro2),
				IntroPageViewController(.appIntro3),
				IntroPageViewController(.appIntro4),
				IntroPageViewController(.arIntro1),
				IntroPageViewController(.arIntro2)
			]
		}
	}
	
	private var currentIndex: Int = 0 {
		didSet {
			bottomHubView.updateContent(elementType: .pageIndicator(currentIndex+1, allPages.count))
		}
	}

	private let pageViewController = UIPageViewController(transitionStyle: .scroll,
														  navigationOrientation: .horizontal,
														  options: nil)
	
	private let afterDismiss: (() -> Void)?
	
	init(mode: Mode, afterDismiss: (() -> Void)? = nil) {
		self.mode = mode
		self.afterDismiss = afterDismiss
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("IntroVC: Deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		pageViewController.delegate = self
		pageViewController.dataSource = self
		pageViewController.view.backgroundColor = .dark90Branded
		
		addChild(pageViewController)
		pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(pageViewController.view)

		DispatchQueue.main.async {
			if let firstPage = self.allPages.first {
				self.pageViewController.setViewControllers([firstPage], direction: .forward, animated: true)
			}
		}

		topHubView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(topHubView)

		bottomHubView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(bottomHubView)

		NSLayoutConstraint.activate([
			pageViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
			pageViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
			pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
			pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			topHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			topHubView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding),

			bottomHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bottomHubView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottomPadding),
			bottomHubView.widthAnchor.constraint(equalTo: topHubView.widthAnchor)
		])
	}

	override func viewDidDisappear(_ animated: Bool) {
		afterDismiss?()
	}
	
	private func pageIndex(_ page: IntroPageViewController) -> Int? {
		for (i, somePage) in allPages.enumerated() {
			if page.page == somePage.page { return i }
		}
		return nil
	}

	// MARK: UIPageViewControllerDelegate

	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		if let page = pendingViewControllers.first as? IntroPageViewController, let index = pageIndex(page) {
			currentIndex = index
		}
	}
	
	// MARK: UIPageViewControllerDataSource

	func pageShifted(by delta: Int, from viewController: UIViewController) -> IntroPageViewController? {
		guard
			let page = viewController as? IntroPageViewController,
			let index = pageIndex(page),
			let shiftedPage = allPages[safe: index+delta]
		 else { return nil }

		return shiftedPage
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		return pageShifted(by: -1, from: viewController)
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		return pageShifted(by: 1, from: viewController)
	}

	// MARK: Button Actions

	private func tapClose() {
		dismiss(animated: true, completion: nil)
	}

	private func tapNext() {
		guard currentIndex < allPages.count-1 else {
			switch mode {
			case .appIntro:
				GameStateManager.shared.game?.didCompleteIntro()
			case .arIntro:
				GameStateManager.shared.game?.didCompleteARIntro()
			case .completeIntro:
				break
			}
			
			dismiss(animated: true, completion: nil)
			return
		}
		let nextViewController = allPages[currentIndex+1]
		pageViewController.setViewControllers([nextViewController],
											  direction: .forward,
											  animated: true,
											  completion: nil)
		currentIndex += 1
	}

	private func tapPrevious() {
		guard currentIndex > 0 else { return }
		let nextViewController = allPages[currentIndex-1]
		pageViewController.setViewControllers([nextViewController],
											  direction: .reverse,
											  animated: true,
											  completion: nil)
		currentIndex -= 1
	}
}

