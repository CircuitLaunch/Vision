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

// Create a image submitter that will scale the image to requisite size
let fixedFrameImageSubmitter = VisionRequest.FixedImageSubmitter(withBounds: CGRect(origin: .zero, size: CGSize(width: 640.0, height: 640.0)))

// Create a reusable CoreMLRequest object
let objectRequest = CoreMLRequest(withModel: vnCoreMLModel!, forSubmitter: fixedFrameImageSubmitter)

struct ContentView: View {

		// An array to store the names of available cameras
    @State private var cameraNames = [String]()
    // A map to associate names with camera ids
    @State private var cameraIds = [String:String]()
    // The name of the currently selected camera
    @State private var selectedCamera = "FaceTime HD Camera"
    
    // The currently captured frame as an NSImage
    @State private var nsImage = NSImage()
    
    @State private var objectObservations: [VNRecognizedObjectObservation] = []

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
    }
    
    // Peform detections on image
    func performDetections(onImage image: CIImage) {
        // Peform object detections
        performObjectDetections(onImage: image)
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
