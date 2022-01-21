//
//  SceneKitView.swift
//  SceneKit+Shader
//
//  Created by skia on 2022/01/20.
//

import MetalKit
import SceneKit
import SwiftUI

struct SceneView: UIViewRepresentable {
    typealias UIViewType = SCNView

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()

        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = .lightGray

        let cameraController = scnView.defaultCameraController

        let scene = SCNScene()
        let root = scene.rootNode

        let otherbox1 = SCNBox(width: 0.5, height: 0.5,
                               length: 0.5, chamferRadius: 0)
        otherbox1.firstMaterial?.diffuse.contents = UIColor.orange
        let otherboxNode1 = SCNNode(geometry: otherbox1)
        otherboxNode1.position = SCNVector3Make(-1, 0, 0)
        root.addChildNode(otherboxNode1)

        let otherbox2 = SCNBox(width: 0.5, height: 0.5,
                               length: 0.5, chamferRadius: 0)
        otherbox2.firstMaterial?.diffuse.contents = UIColor.yellow
        let otherboxNode2 = SCNNode(geometry: otherbox2)
        otherboxNode2.position = SCNVector3Make(1, 0, 0)
        root.addChildNode(otherboxNode2)

        Task {
            let node = await TexturedBox(scnView)
            node.renderingOrder = 2 // rendering order should be different
            root.addChildNode(node)
            await MainActor.run { scnView.draw(scnView.frame) }
        }

        cameraController.target = SCNVector3Make(0, 0, 0)

        scnView.scene = scene

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
