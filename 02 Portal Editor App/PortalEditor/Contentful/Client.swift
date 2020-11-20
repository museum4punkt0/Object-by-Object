import Contentful

extension Client {
	struct Constants {
		static let credentialsFilename = "CMS-Credentials"
		static let credentialsDictSpaceId = "spaceId"
		static let credentialsDictAccessToken = "accessToken"
	}
	
	private static var contentTypes: [EntryDecodable.Type] {
		return [CFStory.self,
				CFPortal.self,
				CFObject.self,
				CFInstitution.self,
				CFObjectText.self,
				CFWorldMap.self]
	}

	public static func preview() -> Client {
		guard
			let url = Bundle.main.url(forResource: Constants.credentialsFilename, withExtension: "plist"),
			let dict = NSDictionary(contentsOf: url) as? [String: String],
			let spaceId = dict[Constants.credentialsDictSpaceId],
			let accessToken = dict[Constants.credentialsDictAccessToken]
		else {
			fatalError()
		}

		return Client(spaceId: spaceId, accessToken: accessToken, host: Host.preview, contentTypeClasses: Client.contentTypes)
	}
}
