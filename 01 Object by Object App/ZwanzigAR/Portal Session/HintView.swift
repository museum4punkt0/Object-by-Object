import UIKit

protocol HintImageDelegate: class {
	func animateHint(to state: HintView.State) -> Void
}

class HintView: UIView {
	enum State {
		case hidden
		case fullDisplay
		case partDisplay
	}

	struct Constants {
		static let headerHeight: CGFloat = 64
		static let width: CGFloat = UIScreen.main.bounds.width * 0.9 < 420 ? UIScreen.main.bounds.width * 0.9 : 420
		static let maxHeight: CGFloat = 200

		static let horizontalPadding: CGFloat = 32
		static let verticalPadding: CGFloat = 32
		static let buttonHeight: CGFloat = 64

		static let separatorColorDark = UIColor.dark100Branded
		static let separatorColorLight = UIColor.dark60Branded
		static let separatorHeight: CGFloat = 1
	}

	enum Style: Equatable {
		case text
		case image

		var title: String {
			switch self {
			case .text:
				return "Hinweis"
			case .image:
				return "Hinweis-Bild"
			}
		}
	}

	public var style: Style
	private var portal: Portal?

	private var hintImage: UIImage?
	private var hintText: String?

	public var state: State = .hidden
	public weak var delegate: HintImageDelegate?

	public var buttonIsDisplayed = false

	public let topView = UIView()
	public let bottomView = UIView()
	public let headerHeight: CGFloat = 64
	public let contentHeight: CGFloat = 300
	public let verticalPaddingOutside: CGFloat = 64

	private var titleLabel = UILabel()
	private let backgroundView = UIView()
	private let dimmerView = UIView()

	private var hintLabelOriginal: UILabel? {
		guard let hintText = hintText else { return nil }
		return UILabel.label(for: .comment, text: hintText, alignment: .center)
	}
	private var hintLabel: UILabel?
	private var heightForLabel: CGFloat {
		let labelHeight = hintLabel?.height(withConstrainedWidth: UIScreen.main.bounds.width * 0.8 - Constants.horizontalPadding * 2) ?? 0
		return labelHeight + Constants.verticalPadding * 2
	}

	private var hintImageViewOriginal: UIImageView {
		return UIImageView(image: hintImage)
	}
	private var hintImageView: UIImageView?
	private var widthForImageView: CGFloat {
		guard let size = hintImageView?.image?.size else { return 0 }
		let aspectRation = size.width / size.height
		return Constants.maxHeight * aspectRation
	}

	public let showImageButton = UIView()
	private let buttonLabel = UILabel.label(for: .buttonDark, text: "Hinweis-Bild zeigen", alignment: .center)
	private lazy var showImageButtonHeightConstraint = NSLayoutConstraint(item: showImageButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0.0)

	init(portal: Portal? = nil) {
		self.style = .text
		self.portal = portal
		self.hintImage = portal?.hintImage?.loadImage()
		self.hintText = portal?.hintText
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

		var constraints = [NSLayoutConstraint]()

		constraints.append(contentsOf: [
			widthAnchor.constraint(equalToConstant: Constants.width)
		])

		backgroundView.clipsToBounds = true
		backgroundView.backgroundColor = .dark90Branded
		backgroundView.layer.cornerRadius = 8
		add(backgroundView, constraints: [
			backgroundView.leftAnchor.constraint(equalTo: leftAnchor),
			backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
			backgroundView.topAnchor.constraint(equalTo: topAnchor),
			backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
		], accumulator: &constraints)

		backgroundView.add(topView, constraints: [
			topView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor),
			topView.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
			topView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
			topView.heightAnchor.constraint(equalToConstant: Constants.headerHeight)
		], accumulator: &constraints)

		titleLabel = UILabel.label(for: .headline2, text: style.title, alignment: .center)
		topView.add(titleLabel, constraints: [
			titleLabel.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
			titleLabel.centerYAnchor.constraint(equalTo: topView.centerYAnchor)
		], accumulator: &constraints)

		let darkSeparator = UIView()
		darkSeparator.backgroundColor = Constants.separatorColorDark
		backgroundView.add(darkSeparator, constraints: [
			darkSeparator.leftAnchor.constraint(equalTo: backgroundView.leftAnchor),
			darkSeparator.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
			darkSeparator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
			darkSeparator.topAnchor.constraint(equalTo: topView.bottomAnchor)
		], accumulator: &constraints)

		let lightSeparator = UIView()
		lightSeparator.backgroundColor = Constants.separatorColorLight
		backgroundView.add(lightSeparator, constraints: [
			lightSeparator.leftAnchor.constraint(equalTo: backgroundView.leftAnchor),
			lightSeparator.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
			lightSeparator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
			lightSeparator.topAnchor.constraint(equalTo: darkSeparator.bottomAnchor)
		], accumulator: &constraints)


		backgroundView.add(bottomView, constraints: [
			bottomView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor),
			bottomView.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
			bottomView.topAnchor.constraint(equalTo: lightSeparator.bottomAnchor),
			bottomView.heightAnchor.constraint(equalToConstant: Constants.maxHeight)
		], accumulator: &constraints)

		// Add image to bottomView with a maxHeight
		hintImageView = hintImageViewOriginal
		if let hintImageView = hintImageView {
			bottomView.add(hintImageView, constraints: [
				hintImageView.centerXAnchor.constraint(equalTo: bottomView.centerXAnchor),
				hintImageView.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
				hintImageView.topAnchor.constraint(equalTo: bottomView.topAnchor),
				hintImageView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
				hintImageView.widthAnchor.constraint(equalToConstant: widthForImageView)
			], accumulator: &constraints)
		}

		dimmerView.backgroundColor = .dark80Branded

		hintLabel = hintLabelOriginal
		if let hintLabel = hintLabel {
			bottomView.add(dimmerView, constraints: [
				dimmerView.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
				dimmerView.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
				dimmerView.topAnchor.constraint(equalTo: bottomView.topAnchor),
				dimmerView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor)
			], accumulator: &constraints)

			dimmerView.add(hintLabel, constraints: [
				hintLabel.centerXAnchor.constraint(equalTo: dimmerView.centerXAnchor),
				hintLabel.centerYAnchor.constraint(equalTo: dimmerView.centerYAnchor),
				hintLabel.leftAnchor.constraint(equalTo: dimmerView.leftAnchor, constant: Constants.horizontalPadding),
				hintLabel.rightAnchor.constraint(equalTo: dimmerView.rightAnchor, constant: -Constants.horizontalPadding)
			], accumulator: &constraints)
		}

		backgroundView.add(showImageButton, constraints: [
			showImageButton.leftAnchor.constraint(equalTo: backgroundView.leftAnchor),
			showImageButton.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
			showImageButton.topAnchor.constraint(equalTo: bottomView.bottomAnchor),
			showImageButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
			showImageButtonHeightConstraint
		], accumulator: &constraints)

		let darkSeparatorForButton = UIView()
		darkSeparatorForButton.backgroundColor = Constants.separatorColorDark
		showImageButton.add(darkSeparatorForButton, constraints: [
			darkSeparatorForButton.leftAnchor.constraint(equalTo: showImageButton.leftAnchor),
			darkSeparatorForButton.rightAnchor.constraint(equalTo: showImageButton.rightAnchor),
			darkSeparatorForButton.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
			darkSeparatorForButton.topAnchor.constraint(equalTo: showImageButton.topAnchor)
		], accumulator: &constraints)

		let lightSeparatorForButton = UIView()
		lightSeparatorForButton.backgroundColor = Constants.separatorColorLight
		showImageButton.add(lightSeparatorForButton, constraints: [
			lightSeparatorForButton.leftAnchor.constraint(equalTo: showImageButton.leftAnchor),
			lightSeparatorForButton.rightAnchor.constraint(equalTo: showImageButton.rightAnchor),
			lightSeparatorForButton.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
			lightSeparatorForButton.topAnchor.constraint(equalTo: darkSeparatorForButton.bottomAnchor)
		], accumulator: &constraints)

		buttonLabel.isHidden = true
		showImageButton.add(buttonLabel, constraints: [
			buttonLabel.centerXAnchor.constraint(equalTo: showImageButton.centerXAnchor),
			buttonLabel.centerYAnchor.constraint(equalTo: showImageButton.centerYAnchor)
		], accumulator: &constraints)

		NSLayoutConstraint.activate(constraints)

		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapUpgrade))
		showImageButton.addGestureRecognizer(tapRecognizer)
	}

	private var initialLocation: CGPoint?
	private var initialFrame: CGRect?
	private var offset: CGPoint?

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let touch = touches.first,
			touches.count == 1
			else { return }

		initialLocation = touch.location(in: superview)
		initialFrame = frame
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let touch = touches.first,
			touches.count == 1,
			let initialLocation = initialLocation,
			let initialFrame = initialFrame
			else { return }

		let newLocation = touch.location(in: superview)

		offset = newLocation - initialLocation

		guard let offset = offset else { return }

		UIView.animate(withDuration: 0.1, animations: { [weak self] in
			guard let self = self else { return }
			self.frame.origin = CGPoint(x: initialFrame.origin.x, y: initialFrame.origin.y + offset.y)
			self.layoutIfNeeded()
		})
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let initialFrame = initialFrame,
			let offset = offset
			else { return }

		if state == .fullDisplay && offset.y > 50 {
			delegate?.animateHint(to: .partDisplay)
		} else if state == .partDisplay && offset.y < -50 {
			delegate?.animateHint(to: .fullDisplay)
		} else {
			UIView.animate(withDuration: 0.5, animations: {
				self.frame.origin = initialFrame.origin
				self.layoutIfNeeded()
			})
		}

		self.initialLocation = nil
		self.initialFrame = nil
		self.offset = nil
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let initialFrame = initialFrame else { return }

		UIView.animate(withDuration: 0.5, animations: {
			self.frame.origin = initialFrame.origin
			self.layoutIfNeeded()
		})

		self.initialLocation = nil
		self.initialFrame = nil
		self.offset = nil
	}

	// Interaction Helpers

	@objc
	private func tapUpgrade(_ gesture: UITapGestureRecognizer) {
		hideUpgradeButton()
		showHintImage()
		style = .image
		setTitleLabel()
	}

	// Helpers

	private func setTitleLabel() {
		titleLabel.attributedText = UILabel.attributedString(for: .headline2, text: style.title)
	}

	public func showHintImage() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: {
				self.dimmerView.alpha = 0.0
			}, completion: { _ in
				self.dimmerView.isHidden = true
			})
		}
	}

	public func showUpgradeButton() {
		guard let _ = hintText, let _ = hintImage else { return }

		showImageButtonHeightConstraint.constant = Constants.buttonHeight
		buttonLabel.isHidden = false
		buttonIsDisplayed = true
	}

	private func hideUpgradeButton() {
		showImageButtonHeightConstraint.constant = 0
		buttonLabel.isHidden = true
		buttonIsDisplayed = false
	}
}
