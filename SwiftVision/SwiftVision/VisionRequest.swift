//
//  VisionRequest.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/24/22.
//

import Foundation
import AVFoundation
import Vision

class VisionRequest {
    // Superclass that submits requests, to be specialized
    // for specific request types
    class Submitter {
        var requests: [VNRequest] = []
    }
    
    // Submitter for this request
    let submitter: Submitter
    // Dispatch queue on which to process the results
    let processingQueue: DispatchQueue
    // Variable to store the VNRequest handle returned by the system
    var request: VNRequest? = nil
    
    // Optional closure to be called when object detection results are available
    private var _onResults: (([Any])->())? = nil
    
    // Constructor
    init(forSubmitter sub: Submitter, onQueue queue: DispatchQueue = DispatchQueue.main) {
        // Keep reference to submitter
        submitter = sub
        // Keep a reference to the queue to use for processing results
        processingQueue = queue
        // Call a member (defined below) to create a VNRequest
        // passing it a callback closure
        request = createVNRequest {
            req, err in
            // Do not process the results on the detection thread
            // but pass it off to a processing thread
            self.processingQueue.async {
                // Extract the results
                if let results = req.results {
                    // Call a custom closure, if available, to
                    // process the results
                    self._onResults?(results)
                }
            }
        }
    }
    
    // Override in a subclass to create and return a specialized VNRequest
    func createVNRequest(_ closure: VNRequestCompletionHandler?)->VNRequest? {
        return nil
    }
}

// Specializations of the Submitter class
extension VisionRequest {

    // Class to submit a detection request on a single image frame
    class ImageSubmitter: Submitter {
        // Override if needed to customize image bounds
        func adjustedBounds(_ bounds: CGRect)->CGRect {
            return bounds
        }
        
        // Submit a vision request on a given image
        func submit(image: CIImage, imgWidth: CGFloat, imgHeight: CGFloat) {
            // Obtain the adjusted bounds, this base class just returns the original bounds
            let bounds = CGRect(origin: .zero, size: CGSize(width: imgWidth, height: imgHeight))
            let adjBounds = adjustedBounds(bounds)
            
            // If the adjusted bounds differ from the image bounds, first scale the image, otherwise use the original image
            if let img = (((imgWidth == adjBounds.width) && (imgHeight == adjBounds.height)) ? image : image.scaled(x: adjBounds.width / imgWidth, y: adjBounds.height / imgHeight)) {
                // Convert it to a CoreGraphics image and then into a Cocoa NSImage
                if let cgImage = sharedContext.createCGImage(img, from: adjustedBounds(bounds)) {
                    // Create a request handler
                    let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage)
                    do {
                        // Submit the image to Vision for detection
                        try imageRequestHandler.perform(self.requests)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    // Specialization of ImageSubmitter to scale image to a known dimension before submission
    class FixedImageSubmitter: ImageSubmitter {
        // Member to store desired bounds
        var fixedBounds: CGRect
        
        // Initializer that takes the desired bounds
        init(withBounds bounds: CGRect) {
            fixedBounds = bounds
        }
        
        // Overridden to return the desired bounds, instead of
        // the original image bounds
        override func adjustedBounds(_: CGRect)->CGRect {
            return fixedBounds
        }
    }
}
