import UIKit
import Contentful

protocol PortalsDisplay {
	func finishedFetchingPortals() -> Void
}

class RootViewController: UITabBarController, UITabBarControllerDelegate {
	private let location = LocationManager.shared
	private let storedData = StoredData.shared

	private var imageView = UIImageView()

	private var missionBoardVC = MissionBoardViewController()
	private var portalSelectionVC = PortalSelectionTableViewController()

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nil, bundle: nil)
		delegate = self
        ContentfulManager.shared.startedFetchingResources = self.startedFetchingResources
        ContentfulManager.shared.finishedFetchingResources = self.finishedFetchingResources
        
        if #available(iOS 15, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithDefaultBackground()
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            
            
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		overrideUserInterfaceStyle = .dark

		let missionBoardNavController = UINavigationController(rootViewController: missionBoardVC)
		missionBoardNavController.tabBarItem = UITabBarItem.init(title: "Karte", image: UIImage(named: "missionBoard"), tag: 0)
		missionBoardNavController.delegate = self

		let portalEditorViewController = UINavigationController(rootViewController: portalSelectionVC)
		portalEditorViewController.tabBarItem = UITabBarItem.init(title: "Liste", image: UIImage(named: "icon_list"), tag: 1)
		portalEditorViewController.delegate = self
		
		setViewControllers([
			missionBoardNavController,
			portalEditorViewController
		], animated: false)
		selectedIndex = 0
	}
	
	func startedFetchingResources() {
		DispatchQueue.main.async {
			let assetUpdateVC = ContentfulUpdateViewController()
			ContentfulManager.shared.startedFetchingAssetFiles = assetUpdateVC.startedFetchingAssetFiles
			ContentfulManager.shared.finishedFetchingAssetFile = assetUpdateVC.finishedFetchingAssetFile
			assetUpdateVC.modalPresentationStyle = .formSheet
			assetUpdateVC.isModalInPresentation = true
			self.present(assetUpdateVC, animated: true)
		}
	}

	func finishedFetchingResources() {
		DispatchQueue.main.async { [weak self] in
			self?.portalSelectionVC.finishedFetchingPortals()
			self?.missionBoardVC.finishedFetchingPortals()
		}
	}
}

extension RootViewController: UINavigationControllerDelegate {
	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		tabBar.isHidden = navigationController.viewControllers.count > 1
	}
}
