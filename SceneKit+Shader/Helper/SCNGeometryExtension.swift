import SceneKit

public extension SCNGeometry {
    // https://stackoverflow.com/questions/17250501/extracting-vertices-from-scenekit

    /**
     Get the vertices (3d points coordinates) of the geometry.
     - returns: An array of SCNVector3 containing the vertices of the geometry.
     */
    func vertices() -> [float3]? {
        let sources = self.sources(for: .vertex)

        guard let source = sources.first else { return nil }

        let stride = source.dataStride / source.bytesPerComponent
        let offset = source.dataOffset / source.bytesPerComponent
        let vectorCount = source.vectorCount

        return source.data.withUnsafeBytes { ptr in
            let buffer = ptr.bindMemory(to: Float.self)
            var result = [float3]()
            for i in 0..<vectorCount {
                let start = i * stride + offset
                let x = buffer[start]
                let y = buffer[start + 1]
                let z = buffer[start + 2]
                result.append(float3(x, y, z))
            }
            return result
        }
    }

    /**
     Get the vertices (3d points coordinates) of the geometry.
     - returns: An array of SCNVector3 containing the vertices of the geometry.
     */
    func uvs() -> [float2]? {
        let sources = self.sources(for: .texcoord)

        guard let source = sources.first else { return nil }

        let stride = source.dataStride / source.bytesPerComponent
        let offset = source.dataOffset / source.bytesPerComponent
        let vectorCount = source.vectorCount

        return source.data.withUnsafeBytes { ptr in
            let buffer = ptr.bindMemory(to: Float.self)
            var result = [float2]()
            for i in 0..<vectorCount {
                let start = i * stride + offset
                let u = buffer[start]
                let v = buffer[start + 1]
                result.append(float2(u, v))
            }
            return result
        }
    }
}
