import UIKit

extension UIColor {
	static let dark100Branded: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
	static let dark90Branded: UIColor = #colorLiteral(red: 0.05490196078, green: 0.05098039216, blue: 0.07843137255, alpha: 1)
	static let dark80Branded: UIColor = #colorLiteral(red: 0.08235294118, green: 0.07843137255, blue: 0.1137254902, alpha: 1)
	static let dark70Branded: UIColor = #colorLiteral(red: 0.1019607843, green: 0.09411764706, blue: 0.1725490196, alpha: 1)
	static let dark60Branded: UIColor = #colorLiteral(red: 0.137254902, green: 0.1294117647, blue: 0.2156862745, alpha: 1)
	static let dark50Branded: UIColor = #colorLiteral(red: 0.1960784314, green: 0.1764705882, blue: 0.2862745098, alpha: 1)

	static let grey90Branded: UIColor = #colorLiteral(red: 0.1921568627, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
	static let grey80Branded: UIColor = #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2705882353, alpha: 1)
	static let grey70Branded: UIColor = #colorLiteral(red: 0.3411764706, green: 0.337254902, blue: 0.3764705882, alpha: 1)
	static let grey60Branded: UIColor = #colorLiteral(red: 0.5098039216, green: 0.4941176471, blue: 0.5921568627, alpha: 1)
	static let grey50Branded: UIColor = #colorLiteral(red: 0.6823529412, green: 0.6666666667, blue: 0.7568627451, alpha: 1)
	static let grey40Branded: UIColor = #colorLiteral(red: 0.8392156863, green: 0.8235294118, blue: 0.9294117647, alpha: 1)

	static let whiteBranded: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

	static let yellowBranded: UIColor = #colorLiteral(red: 0.9725490196, green: 0.7960784314, blue: 0.1843137255, alpha: 1)
	static let greenBranded: UIColor = #colorLiteral(red: 0.003921568627, green: 0.7921568627, blue: 0.4509803922, alpha: 1)
	static let redBranded: UIColor = #colorLiteral(red: 1, green: 0.2745098039, blue: 0.1529411765, alpha: 1)
	static let blueBranded: UIColor = #colorLiteral(red: 0.2117647059, green: 0.3803921569, blue: 0.9921568627, alpha: 1)

	static let champagneBranded: UIColor = #colorLiteral(red: 0.8705882353, green: 0.7843137255, blue: 0.5568627451, alpha: 1)
	static let lightGoldBranded: UIColor = #colorLiteral(red: 0.9843137255, green: 0.8901960784, blue: 0.5568627451, alpha: 1)

  static let pharusPinColor: UIColor = blueBranded
	static let compassColor: UIColor = blueBranded
	static let clueObjectColor: UIColor = yellowBranded
	static let collectionLinkColor: UIColor = .lightGoldBranded
	
	static let pharusOffWhite: UIColor = #colorLiteral(red: 0.8549019608, green: 0.8274509804, blue: 0.7647058824, alpha: 1)
	
//	static let storyColor = [
//		// »Berlin macht von sich reden«
//		"40oZP6kEhmqAGbWLtdsQ8C": #colorLiteral(red: 0.9725490196, green: 0.7960784314, blue: 0.1843137255, alpha: 1),
//		"5mrDNAs0GBidgGtX4uj78k": #colorLiteral(red: 0.8392156863, green: 0.4117647059, blue: 0.7019607843, alpha: 1),
//		"797QUNtLVLGXzUHB1TeQGL": #colorLiteral(red: 0.9725490196, green: 0.1987878193, blue: 0.0815810691, alpha: 1)
//	]

	static let storyColor = [
		Story.StoryColor.yellow: #colorLiteral(red: 0.9725490196, green: 0.7960784314, blue: 0.1843137255, alpha: 1),
		Story.StoryColor.pink: #colorLiteral(red: 0.8392156863, green: 0.4117647059, blue: 0.7019607843, alpha: 1),
		Story.StoryColor.red: #colorLiteral(red: 0.9725490196, green: 0.1987878193, blue: 0.0815810691, alpha: 1),
		Story.StoryColor.brown: #colorLiteral(red: 0.6970055132, green: 0.3993434245, blue: 0.2237497524, alpha: 1),
		Story.StoryColor.ochre: #colorLiteral(red: 0.8759839324, green: 0.5902309763, blue: 0.1456114637, alpha: 1),
		Story.StoryColor.cyan: #colorLiteral(red: 0.5705307699, green: 0.8316846012, blue: 0.7945935053, alpha: 1),
		Story.StoryColor.champagne: UIColor.champagneBranded
	]

}

extension UIColor {
	static var sexyColors: [UIColor] {
		return [
			.systemGreen,
			.systemYellow,
			.systemTeal,
			.systemPink,
			.systemPurple,
			.systemBlue,
			.systemOrange,
			.systemIndigo
		]
	}

	static var random: UIColor {
		let colors = sexyColors
		let index = Int.random(in: 0..<colors.count)
		return colors[index]
	}
}
