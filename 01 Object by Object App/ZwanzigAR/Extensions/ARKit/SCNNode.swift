//
//  SCNNode.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import ARKit

extension SCNNode {

	func setUniformScale(_ scale: Float) {
		self.scale = SCNVector3Make(scale, scale, scale)
	}

	var boundingSize: SCNVector3 {
		boundingBox.max - boundingBox.min
	}
	
	func renderOnTop() {
		self.renderingOrder = 2
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = false
			}
		}
		for child in self.childNodes {
			child.renderOnTop()
		}
	}

	func set(lightingModel: SCNMaterial.LightingModel, recursively: Bool = true) {
		for child in childNodes {
			child.geometry?.firstMaterial?.lightingModel = lightingModel
			if recursively {
				child.set(lightingModel: lightingModel, recursively: recursively)
			}
		}
	}
	
	var allGeometries: [SCNGeometry] {
		var geometries = [SCNGeometry]()
		if let geometry = geometry { geometries.append(geometry) }
		for child in childNodes { geometries += child.allGeometries }
		return geometries
	}
	
	var allMaterials: [SCNMaterial] {
		return allGeometries.flatMap({ $0.materials })
	}

	func nilIfEmpty() -> SCNNode? {
        return childNodes.isEmpty ? nil : self
    }
	
	func moveParents(newParent: SCNNode) {
		if let parent = parent, parent == newParent { return }
		transform = newParent.convertTransform(SCNMatrix4Identity, from: self)
//		transform = newParent.convertTransform(transform, from: self)
		newParent.addChildNode(self)
	}
	
	func logNodeHierarchy(level: Int = 0) {
		print("\(String(repeating: "    ", count: level))\(name ?? "---")")
		for childNode in childNodes {
			childNode.logNodeHierarchy(level: level+1)
		}
	}
}
