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
        scnView.scene = scene

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

        let box = SCNBox(width: 0.5, height: 0.5,
                         length: 0.5, chamferRadius: 0)

        let program = SCNProgram()
        program.vertexFunctionName = "textureSamplerVertex"
        program.fragmentFunctionName = "textureSamplerFragment"
        box.firstMaterial!.program = program

        let filePath = Bundle.main.url(forResource: "box", withExtension: "jpeg")!
        let textureLoader = MTKTextureLoader(device: scnView.device!)
        let options: [MTKTextureLoader.Option: Any] = [
            .generateMipmaps: true,
            .SRGB: true,
        ]
        let texture: MTLTexture
            = try! textureLoader.newTexture(URL: filePath,
                                            options: options)
        let imageProperty = SCNMaterialProperty(contents: texture)
        box.firstMaterial!.setValue(imageProperty, forKey: "customTexture")

        let boxNode = SCNNode(geometry: box)
        root.addChildNode(boxNode)

//        let renderer = Renderer(scnView)
//        boxNode.rendererDelegate = renderer

        cameraController.target = SCNVector3Make(0, 0, 0)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
