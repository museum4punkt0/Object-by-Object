import UIKit

class HubCenterElementView: UIView {
	enum ElementType: Equatable {
		case title(String)
		case subtitle(String)
		case storyProgress(Int, Int)
		case pageIndicator(Int, Int)
		case none
		
		static func ==(lhs: ElementType, rhs: ElementType) -> Bool {
			switch (lhs, rhs) {
			case (.title(_), .title(_)):
				return true
			case (.subtitle(_), .subtitle(_)):
				return true
			case (.storyProgress(_, _), .storyProgress(_, _)):
				return true
			case (.pageIndicator(_, _), .pageIndicator(_, _)):
				return true
			case (.none, .none):
				return true
			default:
				return false
			}
		}
	}

	struct Constants {
		static let labelWidth: CGFloat = 200
	}

	public let elementType: ElementType

	private let label = UILabel()
	private var pageIndicatorView: PageIndicatorView?
	private var storyProgressView: StoryProgressView?
	private var labelHeightConstraint: NSLayoutConstraint?

	init(_ elementType: ElementType) {
		self.elementType = elementType
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		switch elementType {
		case .title(let title):
			setupLabel(title: title)
			label.textColor = .grey40Branded
		case .subtitle(let subtitle):
			setupLabel(title: subtitle)
			label.textColor = .grey60Branded
		case .pageIndicator(let currentCount, let totalCount):
			setupPageIndicator(currentCount, totalCount)
		case .storyProgress(let currentCount, let totalCount):
			setupStoryProgress(currentCount, totalCount)
		case .none:
			break
		}
	}

	// MARK: Helper Functions

	private func setupLabel(title: String) {
		let attributedText = title.uppercasedAttributedString()
		let labelFont = UIFont.font(for: .subtitleSmaller)

		label.attributedText = attributedText
		label.textAlignment = .center
		label.font = labelFont
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping

		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)

		let labelHeight = attributedText.height(withConstrainedWidth: Constants.labelWidth)
		labelHeightConstraint = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: labelHeight)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalTo: label.widthAnchor),
			heightAnchor.constraint(equalTo: label.heightAnchor),

			label.widthAnchor.constraint(equalToConstant: Constants.labelWidth),
			labelHeightConstraint!,
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor)
		])

		setNeedsUpdateConstraints()
	}

	private func setupPageIndicator(_ currentCount: Int, _ totalCount: Int) {
		pageIndicatorView = PageIndicatorView(currentCount, totalCount)

		guard let pageIndicatorView = pageIndicatorView else { return }

		pageIndicatorView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(pageIndicatorView)

			NSLayoutConstraint.activate([
			widthAnchor.constraint(equalTo: pageIndicatorView.widthAnchor),
			heightAnchor.constraint(equalTo: pageIndicatorView.heightAnchor),

			pageIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
			pageIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}

	private func setupStoryProgress(_ currentCount: Int, _ totalCount: Int) {
		storyProgressView = StoryProgressView(max: totalCount, now: currentCount, color: GameStateManager.shared.currentStory?.color ?? .champagneBranded)

		guard let storyProgressView = storyProgressView else { return }

		storyProgressView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(storyProgressView)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalTo: storyProgressView.widthAnchor),
			heightAnchor.constraint(equalTo: storyProgressView.heightAnchor),

			storyProgressView.centerXAnchor.constraint(equalTo: centerXAnchor),
			storyProgressView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}

	// MARK: Update Helper Functions

	public func updateContent(elementType: ElementType) {
		switch elementType {
		case .title(let title):
			updateLabel(title: title)
		case .subtitle(let subtitle):
			updateLabel(title: subtitle)
		case .pageIndicator(let currentCount, let totalCount):
			updatePageIndicator(currentCount, totalCount)
		case .storyProgress(let currentCount, let totalCount):
			updateStoryProgress(currentCount, totalCount)
		default:
			break
		}
	}

	private func updateLabel(title: String) {
		let attributedText = title.uppercasedAttributedString()
		label.attributedText = attributedText

		labelHeightConstraint?.constant = attributedText.height(withConstrainedWidth: Constants.labelWidth)
	}

	private func updatePageIndicator(_ currentCount: Int, _ totalCount: Int) {
		guard let pageIndicatorView = pageIndicatorView else { return }
		pageIndicatorView.updateProgressIndicators(to: currentCount)
	}

	private func updateStoryProgress(_ currentCount: Int, _ totalCount: Int) {
		guard let storyProgressView = storyProgressView else { return }
		storyProgressView.set(color: GameStateManager.shared.currentStory?.color ?? .champagneBranded)
		storyProgressView.updateProgressIndicators(to: currentCount, newMax: totalCount)
	}
}
