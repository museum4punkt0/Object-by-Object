import UIKit

class PageIndicatorView: UIView {
	struct Constants {
		static let indicatorSize: CGFloat = 6
		static let horizontalPadding: CGFloat = 8
	}

	public var totalCount: Int
	public var currentCount: Int

	private var progressIndicators = [UIView]()
	private var totalWidth: CGFloat {
		let totalCountFloat = CGFloat(totalCount)
		return totalCountFloat * Constants.indicatorSize + (totalCountFloat-1) * Constants.horizontalPadding
	}

	init(_ currentCount: Int, _ totalCount: Int) {
		self.totalCount = totalCount
		self.currentCount = currentCount
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		for _ in 0..<totalCount {
			let circle = UIView()
			circle.layer.cornerRadius = Constants.indicatorSize / 2
			circle.translatesAutoresizingMaskIntoConstraints = false
			addSubview(circle)

			progressIndicators.append(circle)
		}

		for i in 0..<progressIndicators.count {
			NSLayoutConstraint.activate([
				progressIndicators[i].centerYAnchor.constraint(equalTo: centerYAnchor),
				progressIndicators[i].widthAnchor.constraint(equalToConstant: Constants.indicatorSize),
				progressIndicators[i].heightAnchor.constraint(equalToConstant: Constants.indicatorSize),
			])

			guard i > 0 else {
				NSLayoutConstraint.activate([
					progressIndicators[i].leftAnchor.constraint(equalTo: leftAnchor)
				])
				continue
			}

			NSLayoutConstraint.activate([
				progressIndicators[i].leftAnchor.constraint(equalTo: progressIndicators[i-1].rightAnchor,
															constant: Constants.horizontalPadding)
			])
		}

		updateProgressIndicators(to: currentCount)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: totalWidth),
			heightAnchor.constraint(equalToConstant: Constants.indicatorSize)
		])
	}


	// MARK: - Helpers

	public func updateProgressIndicators(to newValue: Int) {
		for i in 0..<progressIndicators.count {
			if i == newValue-1 {
				self.progressIndicators[i].backgroundColor = .whiteBranded
			} else {
				self.progressIndicators[i].backgroundColor = UIColor.white.withAlphaComponent(0.2)
			}
		}
		currentCount = newValue
	}
}

