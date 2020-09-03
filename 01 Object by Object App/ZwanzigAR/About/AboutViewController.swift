import UIKit

class AboutViewController: UIViewController {
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let verticalPadding: CGFloat = 16
		
		static let imprintText = """
		IMPRESSUM


		Quellennachweise verwendeter 3D-Objekte


		Dia-Projektor:

		»Diaprex B-11 slide projector«, Malopolska's Virtual Museums (Derivat)
		https://sketchfab.com/3d-models/diaprex-b-11-slide-projector-0b107065c28f4972a72d5053d3f24591


		Fotoapparat:

		»HomeWork_2.3«, Anna Shakil (Derivat)
		https://sketchfab.com/3d-models/homework-23-b23a4ee1a81b4bc59051ca2782ca87f2
		"""
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

	deinit {
		print("AboutVC: Deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .dark90Branded

//		let label = UILabel.label(for: .body, text: "Impressum", alignment: .center)
//		label.translatesAutoresizingMaskIntoConstraints = false
//		view.addSubview(label)
//
//		NSLayoutConstraint.activate([
//			label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//			label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//		])

		view.add(topHubView, activate: [
			topHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.verticalPadding),
			topHubView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding)
		])

		let textView = UITextView()
		textView.isEditable = false
		textView.textColor = .white
		textView.backgroundColor = .clear
		textView.font = UIFont.font(for: .body)
		textView.text = Constants.imprintText
//		textView.text = "Test\nheise.de"
		textView.dataDetectorTypes = .all

		view.add(textView, activate: [
			textView.topAnchor.constraint(equalTo: topHubView.bottomAnchor, constant: Constants.verticalPadding),
			textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.horizontalPadding),
			textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Constants.horizontalPadding),
			textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Constants.verticalPadding)
		])
	}

	private func tapClose() {
		dismiss(animated: true, completion: nil)
	}
}
