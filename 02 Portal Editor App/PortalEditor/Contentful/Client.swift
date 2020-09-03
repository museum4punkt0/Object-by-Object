import Contentful

extension Client {
	private static var contentTypes: [EntryDecodable.Type] {
		return [CFStory.self,
				CFPortal.self,
				CFObject.self,
				CFInstitution.self,
				CFObjectText.self,
				CFWorldMap.self]
	}

	public static func preview() -> Client {
		return Client(spaceId: "____________", accessToken: "___________________________________________", host: Host.preview, contentTypeClasses: Client.contentTypes)
	}
}
