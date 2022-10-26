//
//  FaceDetectionRequest.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/25/22.
//

import Foundation
import Vision

class FaceDetectionRequest: VisionRequest {
    override func createVNRequest(_ completion: VNRequestCompletionHandler?)->VNRequest? {
        return VNDetectFaceRectanglesRequest(completionHandler: completion)
    }
}
