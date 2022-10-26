//
//  FaceObservationsView.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/25/22.
//

import SwiftUI
import Vision

struct FaceObservationsView: View {
    // Bound to external image
    @Binding var nsImage: NSImage
    // Bound to external list of observations
    @Binding var faceObservations: [VNFaceObservation]
    // Stores computed view bounds
    @State var bounds: CGRect = .zero
    
    var body: some View {
        GeometryReader {
            g in
            ZStack {
                // For each observation
                ForEach(faceObservations, id: \.uuid) {
                    observation in
                    // Renormalize detection frames to the bounds of the video frame
                    let box = VNImageRectForNormalizedRect(observation.boundingBox, Int(bounds.size.width), Int(bounds.size.height))
                    // Inner ZStack to encapsulate frame and confidence label text
                    ZStack {
                        // 3-pixel thick frame
                        Rectangle()
                            .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 3.0))
                            // Blend with image for visibility
                            .blendMode(SwiftUI.BlendMode.difference)
                        
                        // Vertical alignment
                        VStack {
                            if let faceCaptureQuality = observation.faceCaptureQuality {
                                Text("Face quality: \(String(format: "%0.2f", faceCaptureQuality))")
                                    .foregroundColor(.white)
                                    .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                    // Blend with image for visibility
                                    .blendMode(SwiftUI.BlendMode.difference)
                            } else {
                                Text("Face")
                                    .foregroundColor(.white)
                                    .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                    // Blend with image for visibility
                                    .blendMode(SwiftUI.BlendMode.difference)
                            }
                            Spacer() // Push content to top and bottom of frame
                            HStack {
                                // If head roll information is available
                                if let roll = observation.roll {
                                    // Display roll angle
                                    Text(String(format: "roll: %0.2lf", Angle(radians: Double(roll.floatValue)).degrees))
                                        .foregroundColor(.white)
                                        // Blend with image for visibility
                                        .blendMode(SwiftUI.BlendMode.difference)
                                }
                                // If head yaw information is available
                                if let yaw = observation.yaw {
                                    // Display yaw angle
                                    Text(String(format: "yaw %0.2lf", Angle(radians: Double(yaw.floatValue)).degrees))
                                        .foregroundColor(.white)
                                        // Blend with image for visibility
                                        .blendMode(SwiftUI.BlendMode.difference)
                                }
                                // If head pitch information is available
                                if let pitch = observation.pitch {
                                    // Display pitch angle
                                    Text(String(format: "pitch %0.2lf", Angle(radians: Double(pitch.floatValue)).degrees))
                                        .foregroundColor(.white)
                                        // Blend with image for visibility
                                        .blendMode(SwiftUI.BlendMode.difference)
                                }
                            }
                        }
                            .padding(10.0)
                    }
                        // Set the size and position of the view to those of the observation frame
                        .frame(width: box.size.width, height: box.size.height)
                        .position(x: box.origin.x + box.size.width * 0.5, y: bounds.size.height - (box.origin.y + box.size.height * 0.5))
                }
            }
                // When the nsImage changes, recalculate the bounds rectangle
                .onChange(of: nsImage) { img in
                        bounds = adjustedBounds(img.size, g.size)
                    }
                // Clip content
                .clipped()
                // Size and position the view to match the image
                .frame(width: bounds.size.width, height: bounds.size.height)
                .position(x: bounds.origin.x + bounds.size.width * 0.5, y: bounds.origin.y + bounds.size.height * 0.5)
        }
    }
    
    // Calculate a size which will fit dst, but keep the aspect ratio of src
    func adjustedSize(_ src: CGSize, _ dst: CGSize)->CGSize {
        if src.width / src.height <= dst.width / dst.height {
            return CGSize(width: src.width * dst.height / src.height, height: dst.height)
        }
        return CGSize(width: dst.width, height: src.height * dst.width / src.width)
    }
    
    // Calculate a rect that will fit, and be centered, in dst, with the aspect ratio of src
    func adjustedBounds(_ src: CGSize, _ dst: CGSize)->CGRect {
        let size = adjustedSize(src, dst)
        return CGRect(origin: CGPoint(x: (dst.width - size.width) * 0.5, y: (dst.height - size.height) * 0.5), size: size)
    }
}

/*
struct FaceObservationsView_Previews: PreviewProvider {
    static var previews: some View {
        FaceObservationsView()
    }
}
*/
