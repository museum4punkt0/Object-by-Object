import UIKit

class IntroTooltip: UIView {

	struct Constants {
		static let width: CGFloat = 240
		static let margin: CGFloat = 20
		
		static let cornerRadius: CGFloat = 4
		static let backgroundColor = UIColor.dark80Branded
		
		static let separatorColorDark = UIColor.dark100Branded
		static let separatorColorLight = UIColor.dark60Branded
		static let separatorHeight: CGFloat = 2

		static let buttonHeight: CGFloat = 44
		
		static let tooltipDimension: CGFloat = 18
		static let tooltipForegroundImage = UIImage(named: "Tooltip Foreground")
		static let tooltipBackgroundImage = UIImage(named: "Tooltip Background")
		
		static let bodyTextCurrentLocation = "Willkommen im Berlin von 1929. Hier beginnt deine Reise …"
		static let bodyTextNavigationTool = "Dein erstes Navigations-Artefakt weist Dir den Weg!"
	}
	
	let button: DialogueCard.DialogueButton?
	let bodyText: String
	
	init(bodyText: String, button: DialogueCard.DialogueButton? = nil) {
		self.bodyText = bodyText
		self.button = button
//		super.init(frame: .zero)
		super.init(frame: CGRect(x: 0, y: 0, width: 2*Constants.cornerRadius, height: 2*Constants.cornerRadius))

		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup() {
		
		let container = UIView()
		container.backgroundColor = Constants.backgroundColor
		container.addBorder(color: Constants.separatorColorLight)
		container.addCornerRadius(Constants.cornerRadius)
		add(container)
		NSLayoutConstraint.activate([container.widthAnchor.constraint(equalToConstant: Constants.width)])
		
		// Body text
		
		let style = UILabel.Style.headline2
		let bodyLabel = UILabel.label(for: style, text: self.bodyText)
		
		let bodyContainer = UIView()
		container.add(bodyContainer, activate: [
			bodyContainer.topAnchor.constraint(equalTo: container.topAnchor),
			bodyContainer.heightAnchor.constraint(equalToConstant: self.bodyText.height(withConstrainedWidth: Constants.width-2*Constants.margin, font: style.font, lineHeightMultiple: style.lineHeightMultiple, kerning: style.kerning) + 2*Constants.margin),
			bodyContainer.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.margin),
			bodyContainer.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.margin)
		])
		bodyContainer.add(bodyLabel)

		// Separator and Button

		if let button = button {
			// Separator
			
			let separatorBase = UIView()
			separatorBase.backgroundColor = Constants.separatorColorDark
			let separatorLowerHalf = UIView()
			separatorLowerHalf.backgroundColor = Constants.separatorColorLight
			separatorBase.add(separatorLowerHalf, activate: [
				separatorLowerHalf.topAnchor.constraint(equalTo: separatorBase.centerYAnchor),
				separatorLowerHalf.bottomAnchor.constraint(equalTo: separatorBase.bottomAnchor),
				separatorLowerHalf.leftAnchor.constraint(equalTo: separatorBase.leftAnchor),
				separatorLowerHalf.rightAnchor.constraint(equalTo: separatorBase.rightAnchor)
			])
			container.add(separatorBase, activate: [
				separatorBase.topAnchor.constraint(equalTo: bodyContainer.bottomAnchor),
				separatorBase.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
				separatorBase.leftAnchor.constraint(equalTo: container.leftAnchor),
				separatorBase.rightAnchor.constraint(equalTo: container.rightAnchor)
			])

			// Button

			container.add(button, activate: [
				button.topAnchor.constraint(equalTo: separatorBase.bottomAnchor),
				button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
				button.leftAnchor.constraint(equalTo: leftAnchor),
				button.rightAnchor.constraint(equalTo: rightAnchor),
				button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
			])
		}
		else {
			NSLayoutConstraint.activate([bodyContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
		}

		// Tooltip
		
		let tooltipBackground = UIImageView(image: Constants.tooltipBackgroundImage)
		add(tooltipBackground, activate: [
			tooltipBackground.widthAnchor.constraint(equalToConstant: Constants.tooltipDimension),
			tooltipBackground.heightAnchor.constraint(equalToConstant: Constants.tooltipDimension),
			tooltipBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
			tooltipBackground.centerYAnchor.constraint(equalTo: container.bottomAnchor)
		])
		tooltipBackground.sendSubviewToBack(self)

		let tooltipForeground = UIImageView(image: Constants.tooltipForegroundImage)
		add(tooltipForeground, activate: [
			tooltipForeground.widthAnchor.constraint(equalToConstant: Constants.tooltipDimension),
			tooltipForeground.heightAnchor.constraint(equalToConstant: Constants.tooltipDimension),
			tooltipForeground.centerXAnchor.constraint(equalTo: centerXAnchor),
			tooltipForeground.centerYAnchor.constraint(equalTo: container.bottomAnchor)
		])
	}

}
