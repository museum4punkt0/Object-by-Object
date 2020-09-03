import UIKit

class SourceMuseumView: UIView {
	struct Constants {
		static let verticalPadding: CGFloat = 16
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 64
		static let logoHeight: CGFloat = 42
	}

	private let titleText: String
	private let logoImage: UIImage?

	private let overtitleText = "Zur Verfügung gestellt durch"

	init(title: String, logo: UIImage?) {
		self.titleText = title
		self.logoImage = logo
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark90Branded

		let overtitle = UILabel.label(for: .annotation, text: overtitleText, alignment: .center, color: .grey50Branded)
		overtitle.translatesAutoresizingMaskIntoConstraints = false
		addSubview(overtitle)

		let title = UILabel.label(for: .headline4, text: titleText, alignment: .center, color: .grey50Branded)
		title.translatesAutoresizingMaskIntoConstraints = false
		addSubview(title)

		let logo = UIImageView(image: logoImage)
		logo.translatesAutoresizingMaskIntoConstraints = false
		addSubview(logo)

		let overtitleHeight = overtitle.height(withConstrainedWidth: UIScreen.main.bounds.width-Constants.horizontalPadding*2)
		let titleHeight = title.height(withConstrainedWidth: UIScreen.main.bounds.width-Constants.horizontalPadding*2)
		let logoWidth = Constants.logoHeight * ((logoImage?.size.width ?? 1)/(logoImage?.size.height ?? 1))

		NSLayoutConstraint.activate([
			overtitle.centerXAnchor.constraint(equalTo: centerXAnchor),
			overtitle.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			overtitle.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topPadding),
			overtitle.heightAnchor.constraint(equalToConstant: overtitleHeight+4),

			title.centerXAnchor.constraint(equalTo: centerXAnchor),
			title.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			title.topAnchor.constraint(equalTo: overtitle.bottomAnchor, constant: Constants.verticalPadding),
			title.heightAnchor.constraint(equalToConstant: titleHeight),

			logo.centerXAnchor.constraint(equalTo: centerXAnchor),
			logo.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Constants.verticalPadding*2),
			logo.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding),
			logo.heightAnchor.constraint(equalToConstant: Constants.logoHeight),
			logo.widthAnchor.constraint(equalToConstant: logoWidth)
		])
	}
}
