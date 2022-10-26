//
//  FaceLandmarkDetectionRequest.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/25/22.
//

import Foundation
import Vision

class FaceLandmarkDetectionRequest: VisionRequest {
    override func createVNRequest(_ completion: VNRequestCompletionHandler?)->VNRequest? {
        let request = VNDetectFaceLandmarksRequest(completionHandler: completion)
        request.revision = VNDetectFaceLandmarksRequestRevision3
        request.constellation = .constellation76Points
        return request
    }
}
