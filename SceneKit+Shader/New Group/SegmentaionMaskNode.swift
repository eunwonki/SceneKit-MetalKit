import SceneKit

public class Renderer: NSObject {
    private var renderTexturePipelineState: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState?
    
    var segmentationTexture: MTLTexture?
    private var viewSize = CGSize.zero
    
    var aspectRatioAdjustment: Float = 0
    var classificationLabelIndex: UInt = 0
    var depthBufferZ: Float = 0
    
    public init(_ sceneView: SCNView) {
        super.init()
        
        let device = sceneView.device!
        let library = device.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "textureSamplerVertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "textureSamplerFragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = sceneView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = sceneView.depthPixelFormat

        guard let pipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else { return }

        renderTexturePipelineState = pipeline

        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.isDepthWriteEnabled = true
        depthStateDesciptor.depthCompareFunction = .greater
        guard let state = device.makeDepthStencilState(descriptor: depthStateDesciptor) else { return }
        depthState = state

        DispatchQueue.main.async { [weak self] in
            self?.viewSize = sceneView.bounds.size
        }
    }
}

extension Renderer: SCNNodeRendererDelegate {
    public func renderNode(_ node: SCNNode,
                           renderer: SCNRenderer,
                           arguments: [String: Any])
    {
        guard let renderTexturePipelineState = renderTexturePipelineState,
              let renderCommandEncoder = renderer.currentRenderCommandEncoder,
              let segmentationTexture = segmentationTexture,
              let depthState = depthState
        else { return }

//        var uniforms = Uniforms(aspectRatioAdjustment: aspectRatioAdjustment,
//                                depthBufferZ: depthBufferZ,
//                                time: Float(CACurrentMediaTime()),
//                                regionOfInterest: roi,
//                                classificationLabelIndex: simd_uint1(classificationLabelIndex))
        
//        guard let uniformsBuffer = renderer.device?.makeBuffer(bytes: &uniforms,
//                                                               length: MemoryLayout<Uniforms>.stride,
//                                                               options: [])
//        else { return }
        
        renderCommandEncoder.setDepthStencilState(depthState)
        renderCommandEncoder.setRenderPipelineState(renderTexturePipelineState)
        renderCommandEncoder.setFragmentTexture(segmentationTexture, index: 0)
//        renderCommandEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
//        renderCommandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
        renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
