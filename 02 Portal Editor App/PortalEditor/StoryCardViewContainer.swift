import UIKit

class StoryCard {
	enum Category {
		case linearStory(Int, Int)
		case collectionObject
		case contrastGroup

		var info: String {
			switch self {
			case .linearStory(let currentCount, let totalCount):
				return "Teil \(currentCount)/\(totalCount)"
			case .contrastGroup:
				return "Kontrastgruppe"
			case .collectionObject:
				return "Sammelobjekt"
			}
		}
	}

	init(title: String, body: String, category: Category) {
		self.title = title
		self.body = body
		self.category = category
	}

	let category: StoryCard.Category
	let title: String
	let body: String
}

class StoryCardViewContainer: UIPassThroughView {
	struct Const {
		static let barWidth: CGFloat = min(500, UIScreen.main.bounds.width - horizontalPadding)
		static let labelInset: CGFloat = 20
		static let bottomMargin: CGFloat = 60
		static let horizontalPadding: CGFloat = 20
		static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
		static let titleFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
		static let infoFont = UIFont.systemFont(ofSize: 16, weight: .regular)
		static let bigVerticalBreak: CGFloat = 10
		static let smallVerticalBreak: CGFloat = 5
		static let lineHeightMultiple: CGFloat = 1.3
	}

	public let storyCardView = UIView()
	private let titleLabel = UILabel()
	private let bodyLabel = UILabel()
	private let infoLabel = UILabel()
	private var topConstraint = NSLayoutConstraint()
	private var heightConstraint = NSLayoutConstraint()
	private var isActive: Bool = false
	private var storyCardQueue = [StoryCard]()

	init() {
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		translatesAutoresizingMaskIntoConstraints = false

		storyCardView.backgroundColor = .asset(.dark)
		storyCardView.translatesAutoresizingMaskIntoConstraints = false
		topConstraint = storyCardView.topAnchor.constraint(equalTo: bottomAnchor, constant: 60)
		heightConstraint = bodyLabel.heightAnchor.constraint(equalToConstant: 0)
		storyCardView.add(to: self, activate: [
			storyCardView.widthAnchor.constraint(equalToConstant: Const.barWidth),
			storyCardView.centerXAnchor.constraint(equalTo: centerXAnchor),
			heightConstraint,
			topConstraint
		])

		titleLabel.textAlignment = .left
		titleLabel.font = Const.titleFont
		titleLabel.textColor = .asset(.champagne)
		titleLabel.numberOfLines = 0
		titleLabel.lineBreakMode = .byWordWrapping
		titleLabel.add(to: storyCardView, activate: [
			titleLabel.topAnchor.constraint(equalTo: storyCardView.topAnchor, constant: Const.labelInset),
			titleLabel.leftAnchor.constraint(equalTo: storyCardView.leftAnchor, constant: Const.labelInset),
		])

		infoLabel.textAlignment = .left
		infoLabel.textColor = .asset(.mediumGrey)
		infoLabel.font = Const.infoFont
		infoLabel.numberOfLines = 0
		infoLabel.lineBreakMode = .byWordWrapping
		infoLabel.add(to: storyCardView, activate: [
			infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Const.smallVerticalBreak),
			infoLabel.leftAnchor.constraint(equalTo: storyCardView.leftAnchor, constant: Const.labelInset)
		])

		bodyLabel.textAlignment = .left
		bodyLabel.font = Const.bodyFont
		bodyLabel.textColor = .asset(.champagne)
		bodyLabel.numberOfLines = 0
		bodyLabel.lineBreakMode = .byWordWrapping
		bodyLabel.add(to: storyCardView, activate: [
			bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Const.bigVerticalBreak),
			bodyLabel.leftAnchor.constraint(equalTo: storyCardView.leftAnchor, constant: Const.labelInset),
			bodyLabel.rightAnchor.constraint(equalTo: storyCardView.rightAnchor, constant: -Const.labelInset),
			bodyLabel.bottomAnchor.constraint(equalTo: storyCardView.bottomAnchor, constant: -Const.labelInset)
		])

//		let closeBtn = UIButton.systemCloseButton()
//		closeBtn.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
//		closeBtn.add(to: self, activate: [
//			closeBtn.rightAnchor.constraint(equalTo: storyCardView.rightAnchor, constant: -Const.labelInset),
//			closeBtn.topAnchor.constraint(equalTo: storyCardView.topAnchor, constant: Const.labelInset),
//			closeBtn.widthAnchor.constraint(equalToConstant: 24),
//			closeBtn.heightAnchor.constraint(equalToConstant: 24)
//		])

		let swipeIndicator = UIView(frame: CGRect(x: 0, y: 8, width: 40, height: 5))
		swipeIndicator.backgroundColor = UIColor.asset(.mediumGrey).withAlphaComponent(0.5)
		swipeIndicator.addCornerRadius()
		swipeIndicator.add(to: storyCardView, activate: [
			swipeIndicator.centerXAnchor.constraint(equalTo: storyCardView.centerXAnchor),
			swipeIndicator.topAnchor.constraint(equalTo: storyCardView.topAnchor, constant: swipeIndicator.frame.origin.y),
			swipeIndicator.widthAnchor.constraint(equalToConstant: swipeIndicator.frame.size.width),
			swipeIndicator.heightAnchor.constraint(equalToConstant: swipeIndicator.frame.size.height)
		])
		
		let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
		swipeDown.direction = .down
		storyCardView.addGestureRecognizer(swipeDown)
		storyCardView.isUserInteractionEnabled = true
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		storyCardView.addCornerRadius(8)
	}

	public func showStoryCard(_ storyCard: StoryCard, override: Bool = true) {
		DispatchQueue.main.async {
			if self.isActive {
				if override {
					// Put current message first in messageQueue and trigger refresh
					self.storyCardQueue = [storyCard] + self.storyCardQueue
					self.set(visible: false)
				}
				else {
					// Put current message last in queue
					self.storyCardQueue.append(storyCard)
				}
				return
			}

			self.infoLabel.text = storyCard.category.info
			self.titleLabel.text = storyCard.title
			self.bodyLabel.text = storyCard.body.trimmingCharacters(in: .whitespacesAndNewlines).hyphenated()
			self.bodyLabel.setLineSpacing(lineHeightMultiple: Const.lineHeightMultiple)
			self.setNeedsLayout()
			self.invalidateIntrinsicContentSize()

			let infoTextHeight = storyCard.category.info.height(withConstrainedWidth: Const.barWidth - 2 * Const.labelInset, font: Const.infoFont)
			let titleTextHeight = storyCard.title.height(withConstrainedWidth: Const.barWidth - 2 * Const.labelInset, font: Const.titleFont)
			let bodyTextHeight = storyCard.body.height(withConstrainedWidth: Const.barWidth - 2 * Const.labelInset, font: Const.bodyFont, lineHeightMultiple: Const.lineHeightMultiple)
			self.heightConstraint.constant =  infoTextHeight + Const.smallVerticalBreak + titleTextHeight + Const.bigVerticalBreak + bodyTextHeight

			self.set(visible: true)
			self.isActive = true
		}
	}

	private func set(visible: Bool) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: {
				let bottomInset = self.safeAreaInsets.bottom + self.heightConstraint.constant + Const.bottomMargin
				self.topConstraint.constant = visible ? -bottomInset : 60
				self.superview?.layoutIfNeeded()
			}, completion: { _ in
				if !visible {
					self.isActive = false
					if self.storyCardQueue.count > 0 {
						self.showStoryCard(self.storyCardQueue.removeFirst())
					}
				}
			})
		}
	}

	@objc
	private func handleSwipeDown() {
		set(visible: false)
	}

	@objc
	private func didTapClose() {
		set(visible: false)
	}
}
