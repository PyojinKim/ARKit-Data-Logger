//
//  AccumulatedPointCloud.swift
//  ARKit-Data-Logger
//
//  Created by kimpyojin on 27/06/2019.
//  Copyright © 2019 Pyojin Kim. All rights reserved.
//

import Foundation
import simd

class AccumulatedPointCloud {
    
    var points = ContiguousArray<simd_float3>()
    var identifiedIndices = [UInt64: Int]()
    var count: Int {
        return self.points.count
    }
    
    init() {
        let baseCapacity = 20000
        self.points.reserveCapacity(baseCapacity)
        self.identifiedIndices.reserveCapacity(baseCapacity)
    }
    
    func appendPointCloud(_ point: vector_float3, _ identifier: UInt64) {
        if let existingIndex = self.identifiedIndices[identifier] {
            self.points[existingIndex] = point
        } else {
            self.identifiedIndices[identifier] = self.points.endIndex
            self.points.append(point)
        }
    }
}
