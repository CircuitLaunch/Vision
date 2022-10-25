//
//  CoreMLRequest.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/24/22.
//

import Foundation
import AVFoundation
import CoreML
import Vision

// Subclass VisionRequest to create CoreML vision requests
class CoreMLRequest: VisionRequest {
    class ImageSubmitter: VisionRequest.Submitter {
    }
    
    let model: VNCoreMLModel
    
    init(withModel model: VNCoreMLModel, forSubmitter submitter: ImageSubmitter, processingQueue queue: DispatchQueue = DispatchQueue.main) {
    }
}
