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
    // Reference to a deep learning model
    let model: VNCoreMLModel
    
    // Constructor
    init(withModel model: VNCoreMLModel, forSubmitter submitter: ImageSubmitter, onQueue queue: DispatchQueue = DispatchQueue.main) {
        // Retain a reference to the deep learning model
        self.model = model
        
        // Pass submitter and processing thread to super
        super.init(forSubmitter: submitter, onQueue: queue)
    }
    
    // Override to create a specialized VNRequest
    override func createVNRequest(_ completion: VNRequestCompletionHandler?)->VNRequest? {
        return VNCoreMLRequest(model: model, completionHandler: completion)
    }
}
