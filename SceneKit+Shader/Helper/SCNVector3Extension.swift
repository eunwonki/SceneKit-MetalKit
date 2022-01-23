//
//  SCNVector3Extension.swift
//  SceneKit+Shader
//
//  Created by wonki on 2022/01/23.
//

import Foundation
import SceneKit

extension SCNVector3 {
    func distance(_ pos: SCNVector3) -> Float {
        return sqrt((x - pos.x) * (x - pos.x) + (y - pos.y) * (y - pos.y) + (z - pos.z) * (z - pos.z))
    }
}
