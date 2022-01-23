import MetalKit
import SceneKit

public class TexturedBox: SCNNode {
    struct NodeMatrix: sizeable {
        var modelTransform = float4x4()
        var modelViewProjectionTransform = float4x4()
        var modelViewTransform = float4x4()
        var normalTransform = float4x4()
        var boundingBox = float2x3()
        var depthBufferZ: Float = 0
    }
    
    struct VertexIn: sizeable {
        var position = float3()
        var normal = float3()
        var uv = float2()
    }
    
    private var renderTexturePipelineState: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState!
    
    var texture: MTLTexture!
    let box = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0)
    private var vertexBuffer: MTLBuffer!
    private var vertexCount = 0
    private var indexBuffer: MTLBuffer!
    private var indexCount = 0
    private var nodeMatrix = NodeMatrix()
    
    public init(_ sceneView: SCNView) async {
        super.init()
        
        try? // need time to set right SCNGeometry vertices
            await Task.sleep(nanoseconds: 100_000_000)
        
        rendererDelegate = self
        
        let device = sceneView.device!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = sceneView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = sceneView.depthPixelFormat
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor()
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library!.makeFunction(name: "textureSamplerVertex")
        pipelineDescriptor.fragmentFunction = library!.makeFunction(name: "textureSamplerFragment")
        
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.isDepthWriteEnabled = true
        depthStateDesciptor.depthCompareFunction = .greater

        do {
            renderTexturePipelineState
                = try await device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            depthState
                = device.makeDepthStencilState(descriptor: depthStateDesciptor)
        } catch {
            fatalError("\(error)")
        }
        
        setVertexBuffer(device: device)
        loadTextures(device: device)
    }
    
    private func vertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = float3.size
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = float3.size + float3.size
        
        vertexDescriptor.layouts[0].stride = VertexIn.stride
        
        return vertexDescriptor
    }
    
    private func setVertexBuffer(device: MTLDevice) { // just set vertices and uvs
        let vertices = box.vertices()!
        let uvs = box.uvs()!
        
        vertexCount = vertices.count
        
        var vins: [VertexIn] = []
        for i in 0 ..< vertexCount {
            let vin = VertexIn(position: vertices[i],
                               normal: float3(),
                               uv: uvs[i])
            vins.append(vin)
        }

        vertexBuffer = device.makeBuffer(bytes: vins,
                                         length: VertexIn.stride(vertexCount),
                                         options: [])!
        
        let fData = (box.elements.first!.data as NSData).bytes
            .assumingMemoryBound(to: Int16.self)
        let indexByte = box.elements.first!.bytesPerIndex
        indexCount = box.elements.first!.primitiveCount * 3
        indexBuffer = device.makeBuffer(bytes: fData,
                                        length: indexByte * indexCount,
                                        options: [])
    }
    
    private func updateNodeMatrix(_ camNode: SCNNode,
                                  _ viewport: CGRect,
                                  _ useReverseZ: Bool)
    { // just set modelviewprojection transform and depth buffer z
        guard let camera = camNode.camera else {
            return
        }
        
        let modelMatrix = worldTransform
        let viewMatrix = SCNMatrix4Invert(camNode.transform)
        let projectionMatrix
            = camera.projectionTransform(withViewportSize: viewport.size)
        
        let viewProjection = SCNMatrix4Mult(viewMatrix, projectionMatrix)
        let modelViewProjection = SCNMatrix4Mult(modelMatrix, viewProjection)
        nodeMatrix.modelViewProjectionTransform = float4x4(modelViewProjection)
        
        let distance = camNode.position.distance(worldPosition)
        let z = calculateFragmentDepth(usingCamera: camera,
                                       distanceToTarget: distance,
                                       usesReverseZ: useReverseZ)
        nodeMatrix.depthBufferZ = z
    }
    
    // Calculate the z buffer value so we can use it in the fragment shader.
    // For the sake of occulsion, we need to write this value into the depth buffer.
    // This will happen in the fragment shader.
    private func calculateFragmentDepth(usingCamera camera: SCNCamera, distanceToTarget: Float, usesReverseZ: Bool) -> Float {
        // SceneKit uses a reverse z buffer since iOS 13. In case it uses a reverse buffer.
        // We'll need to swap the near and far planes.
        let zFar = usesReverseZ ? camera.zNear : camera.zFar
        let zNear = usesReverseZ ? camera.zFar : camera.zNear
        let range = 2.0 * zNear * zFar
        // The depth value in in normalized device coordinates [-1, 1].
        let fragmentDepth = (zFar + zNear - range / Double(distanceToTarget)) / (zFar - zNear)
        // Convert to normalized coordinates [0, 1].
        return Float((fragmentDepth + 1.0) / 2.0)
    }
    
    private func loadTextures(device: MTLDevice) {
        let filePath = Bundle.main.url(forResource: "box", withExtension: "jpeg")!
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .generateMipmaps: true,
            .SRGB: true,
        ]
        texture = try! textureLoader.newTexture(URL: filePath,
                                                options: options)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TexturedBox: SCNNodeRendererDelegate {
    public func renderNode(_ node: SCNNode,
                           renderer: SCNRenderer,
                           arguments: [String: Any])
    {
        guard let renderTexturePipelineState = renderTexturePipelineState,
              let renderCommandEncoder = renderer.currentRenderCommandEncoder,
              let camNode = renderer.pointOfView,
              let texture = texture
        else { return }
        
        updateNodeMatrix(camNode, renderer.currentViewport, renderer.usesReverseZ)
        guard let nodeBuffer
            = renderer.device?.makeBuffer(bytes: &nodeMatrix,
                                          length: NodeMatrix.stride,
                                          options: [])
        else { return }
        
        renderCommandEncoder.setDepthStencilState(depthState)
        renderCommandEncoder.setRenderPipelineState(renderTexturePipelineState)
        renderCommandEncoder.setFragmentTexture(texture, index: 0)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBuffer(nodeBuffer, offset: 0, index: 1)
        renderCommandEncoder.setFragmentBuffer(nodeBuffer, offset: 0, index: 1)
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: indexCount,
                                                   indexType: .uint16,
                                                   indexBuffer: indexBuffer,
                                                   indexBufferOffset: 0)
    }
}
