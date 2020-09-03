import ARKit

extension ARSession {
//	func configureAndRun(delegate: ARSessionDelegate, planeDetection: ARWorldTrackingConfiguration.PlaneDetection = [.horizontal], worldMapURL: URL, options: ARSession.RunOptions = [.removeExistingAnchors]) -> Int {
//		let configuration = ARWorldTrackingConfiguration()
//		configuration.planeDetection = planeDetection
//		var foundWorldMapSize = 0
//		if let (worldMap, size) = loadWorldMap(worldMapURL: worldMapURL) {
//			configuration.initialWorldMap = worldMap
//			foundWorldMapSize = size
//		}
//		self.delegate = delegate
//
//		self.run(configuration, options: options)
//		return foundWorldMapSize
//	}
	
//	// MARK: - Persistent AR
//	func loadWorldMap(worldMapURL: URL) -> (ARWorldMap, Int)? {
//		if
//			let data = try? Data(contentsOf: worldMapURL),
//			let worldMap = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ARWorldMap
//		{
//			return (worldMap, data.count)
//		}
//		return nil
//	}
//
//	func saveWorldMap(worldMapURL: URL, completion: @escaping (Int) -> Void) {
//		getCurrentWorldMap { (worldMap, _) in
//			if let worldMap = worldMap, let data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) {
//				try? data.write(to: worldMapURL)
//				completion(data.count)
//			}
//		}
//	}
//
//	func removeWorldMap(worldMapURL: URL) {
//		try? FileManager.default.removeItem(at: worldMapURL)
//	}
}
