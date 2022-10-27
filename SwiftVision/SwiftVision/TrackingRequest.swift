//
//  TrackingRequest.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/25/22.
//

import Foundation
import AVFoundation
import Vision

class TrackingRequest : VisionRequest {
    var objectObservation: VNDetectedObjectObservation
    
    init(withInitialObservation obs: VNDetectedObjectObservation, forSubmitter submitter: SequenceSubmitter, onQueue queue: DispatchQueue = DispatchQueue.main) {
        self.objectObservation = obs
        
        // Pass submitter and processing thread to super
        super.init(forSubmitter: submitter, onQueue: queue)
    }
    
    // Vision has limited resources when it comes to tracking. It's
    // advisable to reuse tracking requests whenever possible
    func reuse(forNewObservation obs: VNDetectedObjectObservation) {
        // Cast super's reference to the VNRequest to a VNTrackObjectRequest
        if let request = self.request as? VNTrackObjectRequest {
            // Update the input observation
            request.inputObservation = obs
            // Reset the last frame flag
            request.isLastFrame = false
        }
        // Update the initial object observation
        self.objectObservation = obs
    }
    
    override func createVNRequest(_ completion: VNRequestCompletionHandler?)->VNRequest? {
        let request = VNTrackObjectRequest(detectedObjectObservation: objectObservation, completionHandler: completion)
        return request
    }
}

extension VisionRequest {
    class SequenceSubmitter : Submitter {
        // This handler needs to persist across frames, so
        // instantiate this as a member of the submitter
        // rather than ad hoc in the submit method
        var requestHandler: VNSequenceRequestHandler
        
        override init() {
            requestHandler = VNSequenceRequestHandler()
        }
        
        // Every once in a while, when there are no
        // active tracking requests, it's a good idea
        // to instantiate a new VNSequenceRequestHandler
        // to allow Vision to free up some resources.
        func reset() {
            requestHandler = VNSequenceRequestHandler()
        }
        
        // This is why we used an array to store the requests in
        // the super class, because in some cases, like this one,
        // there can be more than one requests associated with
        // a single request handler.
        func submit(image: CIImage) {
            do {
                try requestHandler.perform(self.requests, on: image)
            } catch {
                print(error)
            }
        }
    }
}

