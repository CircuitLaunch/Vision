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

    var body: some View {
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
			// Image to display the captured frames
            Image(nsImage: nsImage)
				.resizable()
				.aspectRatio(contentMode: .fit)
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
                                    var bounds = CGRect(x: 0, y: 0, width: width, height: height)
                                    // Create a CoreImage image class with the buffer
                                    var ciImage = CIImage(cvImageBuffer: buffer)
                                    
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
                .onChange(of: selectedCamera) { newValue in
                        // Restart when the user selects another camera
                        if let selectedId = cameraIds[selectedCamera] {
                            videoCapture.start(using: selectedId)
                        }
                    }
        }
            .padding()
    }
    
    // Enable detections
    func enableDetections() {
        // To be implemented in the next tutorial
    }
    
    // Peform detections on image
    func performDetections(onImage image: CIImage) {
        // To be implemented in the next tutorial
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
