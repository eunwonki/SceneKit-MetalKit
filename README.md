# SceneKit + Metal Shader

Render node using SCNNodeRendererDelegate and metal shader.  
Without SCNProgram (without scnshadable protocol...)    
Without SCNTechnique    
     
       
You can these things.
- can represent Depth with othre node.  
- can pass input mtlbuffer to shader.  
- can implement multi-pass rendering (I mean any custom rendering...) 
     
You can't these things by this way.
(Almost are correspondence with other node in scenekit)
- can't use geometry of scnnode.
- can't use transparency with other scnnode (included in geometry).
- can't use lightmodel of scenekit.
- can't use rendering order with other scnnnode


Maybe it is possible if we implement scnshadable with four metal shader.    
([scnshadable](https://developer.apple.com/documentation/scenekit/scnshadable), But it has a few documents and examples.)
- geometry
- surface
- lightingModel
- fragment

## Screenshots (Implement just textured box)
![](https://github.com/eunwonki/SceneKit-MetalShader/blob/main/Screenshot/1.png?raw=true)
     
        
### in front of other node
![](https://github.com/eunwonki/SceneKit-MetalShader/blob/main/Screenshot/3.png?raw=true)

    
### back of other node
![](https://github.com/eunwonki/SceneKit-MetalShader/blob/main/Screenshot/2.png?raw=true)