//
//  ContentView.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/24/22.
//

import SwiftUI
import AVFoundation
import Vision

// Instantiate a VideoCapture object
let videoCapture = VideoCapture()

// Create a CoreImage context for image manipulation
let sharedContext = CIContext(options: [.useSoftwareRenderer: false])

// URL for the YOLOv5s model embedded in the main bundle
let yolov5sURL = Bundle.main.url(forResource: "yolov5s", withExtension: "mlmodelc")

// Instantiate an MLModel with the YOLOv5s model
let mlModel = try? MLModel(contentsOf: yolov5sURL!)

// Wrap it in a VNCoreMLModel so Vision can deal with it
let vnCoreMLModel = try? VNCoreMLModel(for: mlModel!)

// Create an image submitter that will scale the image to requisite size
let fixedFrameImageSubmitter = VisionRequest.FixedImageSubmitter(withBounds: CGRect(origin: .zero, size: CGSize(width: 640.0, height: 640.0)))

// Create a reusable CoreMLRequest object
let objectRequest = CoreMLRequest(withModel: vnCoreMLModel!, forSubmitter: fixedFrameImageSubmitter)

// Create an image submitter
let imageSubmitter = VisionRequest.ImageSubmitter()

// Create a reusable FaceDetectionRequest object
let faceRequest = FaceDetectionRequest(forSubmitter: imageSubmitter)

// Create a second image submitter
let imageSubmitter2 = VisionRequest.ImageSubmitter()

// Create a reusable FaceLandmarkDetectionRequest object
let faceLandmarkRequest = FaceLandmarkDetectionRequest(forSubmitter: imageSubmitter2)

// Create a sequence submitter
let sequenceSubmitter = VisionRequest.SequenceSubmitter()

// A dictionary of tracks
var trackingRequests: [UUID: TrackingRequest] = [:]
// A pool of reusable tracking requests
var trackerPool: [TrackingRequest] = []

struct ContentView: View {

    // An array to store the names of available cameras
    @State private var cameraNames = [String]()
    // A map to associate names with camera ids
    @State private var cameraIds = [String:String]()
    // The name of the currently selected camera
    @State private var selectedCamera = "FaceTime HD Camera"
    
    // The currently captured frame as an CIImage
    @State private var ciImage = CIImage()
    
    // The currently captured frame as an NSImage
    @State private var nsImage = NSImage()
    
    @State private var objectObservations: [VNRecognizedObjectObservation] = []
    
    @State private var faceObservations: [VNFaceObservation] = []
    
    @State private var landmarkObservations: [VNFaceObservation] = []
    
    @State private var trackedObservations: [UUID: VNDetectedObjectObservation] = [:]

    var body: some View {
        ZStack {
            GeometryReader {
                outer in
                // Vertical stack containing a Picker, and an Image
                VStack(spacing: 10.0) {
                    // Create a Picker named "Cameras" and bind
                    // selectedCamera to its selection variable
                    Picker("Cameras", selection: $selectedCamera) {
                        // Populate the picker with the camera names
                        ForEach(cameraNames, id: \.self) { name in
                            // The displayed text is the name of each camera
                            // The tag is the value to return in selectedCamera
                            // when the user picks an option; in this case is
                            // also the camera name
                            Text(name).tag(name)
                        }
                    }
                        .pickerStyle(.segmented)
                    ZStack {
                        // Image to display the captured frames
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        ObjectObservationsView(
                            nsImage: $nsImage,
                            objectObservations: $objectObservations)
                        FaceObservationsView(
                            nsImage: $nsImage,
                            faceObservations: $faceObservations)
                        FaceLandmarksView(
                            nsImage: $nsImage,
                            faceObservations: $landmarkObservations)
                        TrackedObservationsView(
                            nsImage: $nsImage,
                            trackedObservations: $trackedObservations)
                    }
                        .onAppear {
                                // Get a list of attached cameras
                                let discoveredCameraList =
                                    AVCaptureDevice.DiscoverySession(
                                        deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                        mediaType: .video,
                                        position: .unspecified
                                    ).devices
                                // Populate the names array and the name:id map
                                for discovered in discoveredCameraList {
                                    cameraNames.append(discovered.localizedName)
                                    cameraIds[discovered.localizedName] = discovered.uniqueID
                                }
                                
                                // Attach a closure to the videoCapture object  handle incoming frames
                                videoCapture
                                    .onCapturedImage { buffer in
                                        if let buffer = buffer {
                                            // Get the dimensions of the image
                                            let width = CVPixelBufferGetWidth(buffer)
                                            let height = CVPixelBufferGetHeight(buffer)
                                            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
                                            
                                            // Create a CoreImage image class with the buffer
                                            let ciImage = CIImage(cvImageBuffer: buffer)
                                            
                                            // Cache this CIImage for facelandmark detection
                                            self.ciImage = ciImage
                                            
                                            // Call method to perform detections
                                            performDetections(onImage: ciImage)
                                            
                                            // Convert it to a CoreGraphics image and then into a Cocoa NSImage
                                            if let cgImage = sharedContext.createCGImage(ciImage, from: bounds) {
                                                nsImage = NSImage(cgImage: cgImage, size: bounds.size)
                                            }
                                        }
                                    }
                                    
                                // Call method to enable detections
                                enableDetections()
                                                    
                                // Start capturing
                                if let selectedId = cameraIds[selectedCamera] {
                                    videoCapture.start(using: selectedId)
                                }
                            }
                            
                        .onChange(of: selectedCamera) {
                                newValue in
                                // Restart when the user selects another camera
                                if let selectedId = cameraIds[selectedCamera] {
                                    videoCapture.start(using: selectedId)
                                }
                            }
                }
            }
        }
            .padding(EdgeInsets(top: 5.0, leading: 5.0, bottom: 10.0, trailing: 5.0))
    }
    
    // Enable detections
    func enableDetections() {
        // Enable object detections
        enableObjectDetections()
        // Enable face detections
        enableFaceDetections()
        // Enable face landmark detections
        enableFaceLandmarkDetections()
    }
    
    // Peform detections on image
    func performDetections(onImage image: CIImage) {
        // Peform object detections
        performObjectDetections(onImage: image)
        // Perform face detections
        performFaceDetections(onImage: image)
        // Perform tracking
        performTracking(onImage: image)
    }
    
    // Enable object detection
    func enableObjectDetections() {
        // This sets the closure which will be called when objects are detected
        // and enables detecting (detection only actually happens when a submit()
        // message is sent to a submitter)
        objectRequest.enable {
            results in
            // Create empty list of observations
            var objectObservations: [VNRecognizedObjectObservation] = []
            // Iterate through the results of type VNRecognizedObjectObservation
            for result in results where result is VNRecognizedObjectObservation {
                // Ensure a correct cast
                if let objectObservation = result as? VNRecognizedObjectObservation {
                    // Append the observation to the list
                    objectObservations.append(objectObservation)
                }
            }
            // Modifications to SwiftUI state must be performed on the main thread
            DispatchQueue.main.async {
                // Swap in the new list
                self.objectObservations = objectObservations
            }
        }
    }
    
    // Perform object detections
    func performObjectDetections(onImage image: CIImage) {
        // Trigger a detection by submitting an image
        fixedFrameImageSubmitter.submit(
            image: image,
            imgWidth: image.extent.width,
            imgHeight: image.extent.height)
    }
    
    // Enable face detections
    func enableFaceDetections() {
        // This sets the closure which will be called when faces are detected
        // and enables detecting (detection only actually happes when a submit()
        // message is sent to a submitter)
        faceRequest.enable {
            results in
            // Create empty list of observations
            var faceObservations: [VNFaceObservation] = []
            // Iterate through the results of type VNFaceObservation
            for result in results where result is VNFaceObservation {
                // Ensure a correct cast
                if let faceObservation = result as? VNFaceObservation {
                    // Append the observation to the list
                    faceObservations.append(faceObservation)
                    // Track this face
                    trackObservation(faceObservation)
                }
            }
            // Modifications to SwiftUI state must be performed on the main thread
            DispatchQueue.main.async {
                // Swap in the new list
                self.faceObservations = faceObservations
            }
            
            // If there were face observations, they have been cached by Vision.
            // Trigger face landmark detection by submitting the image again.
            if faceObservations.count > 0 {
                imageSubmitter2.submit(
                    image: self.ciImage,
                    imgWidth: self.ciImage.extent.size.width, imgHeight: self.ciImage.extent.size.height)
            } else {
                // If there were no face detections, we need to also clear any old landmark observations
                DispatchQueue.main.async {
                    self.landmarkObservations = []
                }
            }
        }
    }
    
    // Perform face detections
    func performFaceDetections(onImage image: CIImage) {
        // Trigger a detection by submitting an image
        imageSubmitter.submit(
            image: image,
            imgWidth: image.extent.width,
            imgHeight: image.extent.height)
    }
    
    // Enable face landmark detections
    func enableFaceLandmarkDetections() {
        // This sets the closure which will be called when faces are processed
        // for landmark detection.
        faceLandmarkRequest.enable {
            results in
            // Create empty list of observations
            var faceObservations: [VNFaceObservation] = []
            // Iterate through the results of type VNFaceObservation
            for result in results where result is VNFaceObservation {
                // Ensure a correct cast
                if let faceObservation = result as? VNFaceObservation {
                    // Append the observation to the list
                    faceObservations.append(faceObservation)
                }
            }
            // Modifications to SwiftUI state must be performed on the main thread
            DispatchQueue.main.async {
                // Swap in the new list
                self.landmarkObservations = faceObservations
            }
            
        }
    }
    
    /*
    // This doesn't seem to work. Not sure why, but I'm keeping this code in case
    // I figure it out later
    func pruneTrackers() {
        var newTrackers: [UUID: TrackingRequest] = [:]
        for(id, tracker) in trackingRequests {
            var reuptake = true
            if !newTrackers.keys.contains(id) {
                // Get bounds of observation
                let trackedBounds = tracker.objectObservation.boundingBox
                for (_, newTracker) in newTrackers {
                    let newBounds = newTracker.objectObservation.boundingBox
                    // Calculate the intersection bounds
                    let intersection = trackedBounds.intersection(newBounds)
                    // If there is ANY overlap at all, prune it
                    if !intersection.isEmpty {
                        reuptake = false
                    }
                }
                if reuptake {
                    newTrackers[id] = tracker
                } else {
                    print("Pruning tracker \(tracker.objectObservation.uuid)")
                    tracker.disable()
                }
            }
        }
        trackingRequests = newTrackers
    }
    */
    
    // Attempt to determine if an observation is already being tracked
    func alreadyTracked(_ observation: VNDetectedObjectObservation)->Bool {
        // Scan through existing requests
        for (_, request) in trackingRequests {
            // Get bounds of tracked observation
            let trackedBounds = request.objectObservation.boundingBox
            // Get bounds of current observation
            let observedBounds = observation.boundingBox
            // Calculate the intersection bounds
            let intersection = trackedBounds.intersection(observedBounds)
            // If there is ANY overlap at all, assume this is being tracked
            if !intersection.isEmpty {
                return true
            }
        }
        return false
    }
    
    // Track an observation
    func trackObservation(_ observation: VNDetectedObjectObservation) {
        // If we are not currently tracking any observations, take this opportunity to
        // reset the sequenceSubmitter to free tracker resources for reuse
        if trackingRequests.count == 0 && trackerPool.count > 0 {
            sequenceSubmitter.reset()
            trackerPool = []
        }
        
        // Don't track if this observation is already being tracked
        if alreadyTracked(observation) {
            return
        }
        
        // I've read that Vision only supports a max of 16 simultaneous
        // tracking requests, and experimentation bears this out, but
        // I'm not taking chances. Increase this number at your own risk.
        if trackingRequests.count < 10 {
            var trackingRequest: TrackingRequest
            
            // If there are TrackingRequest objects in the pool,
            // pop the last one for reuse
            if let last = trackerPool.last {
                print("Reusing tracking request for \(observation.uuid)")
                trackerPool.removeLast()
                trackingRequest = last
                trackingRequest.reuse(forNewObservation: observation)
            // Otherwise, create a new tracking request
            } else {
                print("Creating tracking request for \(observation.uuid)")
                trackingRequest = TrackingRequest(withInitialObservation: observation, forSubmitter: sequenceSubmitter)
            }
            
            // Add it to the dictionary
            trackingRequests[observation.uuid] = trackingRequest
            
            // Enable this tracking request for this observation
            trackingRequest.enable {
                // Handle results
                results in
                // Iterate through results
                for result in results {
                    // Assume this is the last frame
                    var reuptake = false
                    // Cast the result to a VNDetectedObjectObservation
                    if let observation = result as? VNDetectedObjectObservation {
                        // If the confidence is greater than 0.3
                        if observation.confidence > 0.3 {
                            // And there's a valid tracking request
                            if let request = trackingRequests[observation.uuid] {
                                // Reuse this request with the updated observation
                                request.reuse(forNewObservation: observation)
                                // Prevent this request from being recycled
                                reuptake = true
                                // Update the tracked observations for SwiftUI
                                DispatchQueue.main.async {
                                    trackedObservations[observation.uuid] = observation
                                }
                            }
                        } else {
                            if let request = trackingRequests[observation.uuid], let vnRequest = request.request as? VNTrackObjectRequest {
                                vnRequest.isLastFrame = true
                            }
                        }
                        // If we've lost track of this observation
                        if !reuptake {
                            // Pull the TrackingRequest object associated with this obervation
                            if let request = trackingRequests[observation.uuid] {
                                print("Recycling tracking request \(observation.uuid)")

                                // Disable the request
                                request.disable()
                                // Remove it from the map of current TrackingRequests
                                trackingRequests[observation.uuid] = nil
                                // Return it to the pool
                                trackerPool.append(request)
                                // Remove this observation from the trackedObservation map
                                DispatchQueue.main.async {
                                    trackedObservations[observation.uuid] = nil
                                    print("Observations tracked: \(trackingRequests.count), in circulation: \(trackingRequests.count + trackerPool.count)")
                                }
                            }
                        }
                    }
                }
            }
        }
        print("Observations tracked: \(trackingRequests.count), in circulation: \(trackingRequests.count + trackerPool.count)")
    }
    
    func performTracking(onImage image: CIImage) {
        // pruneTrackers()
        sequenceSubmitter.submit(image: image)
    }
}

// Extension to make it easy to scale a CIImage
extension CIImage {
    // Fixed aspect ratio
    func scaled(by scale: Double)->CIImage? {
        if let filter = CIFilter(name: "CILanczosScaleTransform") {
            filter.setValue(self, forKey: "inputImage")
            filter.setValue(scale, forKey: "inputScale")
            filter.setValue(1.0, forKey: "inputAspectRatio")
            return filter.value(forKey: "outputImage") as? CIImage
        }
        return nil
    }
    
    // Variable aspect ratio
    func scaled(x: CGFloat, y: CGFloat)->CIImage? {
        if let filter = CIFilter(name: "CIAffineTransform") {
            let xform = NSAffineTransform(transform: AffineTransform(scaleByX: x, byY: y))
            filter.setValue(self, forKey: "inputImage")
            filter.setValue(xform, forKey: "inputTransform")
            return filter.value(forKey: "outputImage") as? CIImage
        }
        return nil
    }
}
