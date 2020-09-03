import ARKit

extension SCNNode {
    static let debugNodeName: String = "Plane Debug Node"
}

extension ARPlaneAnchor {
    func debugNode() -> SCNNode {
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        let transformPosition = SCNVector3.positionFromTransform(transform)
		let planeCenter = SCNVector3(transformPosition.x + center.x, transformPosition.y, transformPosition.z + center.z)
		
        plane.materials.first?.diffuse.contents = UIColor(hue: 0.5, saturation: 1.0, brightness: 0.5, alpha: 0.9)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = SCNNode.debugNodeName
		planeNode.position = planeCenter
        planeNode.eulerAngles.x = -.pi / 2 // SCNPlanes are vertically oriented as standard
        
        return planeNode
    }
    
    func updateDebugNode(in node: SCNNode) {
        guard
              let debugNode = node.childNode(withName: SCNNode.debugNodeName, recursively: false),
              let plane = debugNode.geometry as? SCNPlane
        else { return }

        debugNode.position = SCNVector3(center.x, 0, center.z)
        
        plane.width = CGFloat(extent.x)
        plane.height = CGFloat(extent.z)
    }
}
