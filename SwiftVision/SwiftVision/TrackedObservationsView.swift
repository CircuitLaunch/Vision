//
//  TrackedObservationsView.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/26/22.
//

import SwiftUI
import Vision

struct TrackedObservationsView: View {
    // Bound to external image
    @Binding var nsImage: NSImage
    // Bound to external list of observations
    @Binding var trackedObservations: [UUID: VNDetectedObjectObservation]
    // Stores computed view bounds
    @State var bounds: CGRect = .zero
    
    var body: some View {
        GeometryReader {
            g in
            ZStack {
                // For each observation
                ForEach(Array(trackedObservations.keys), id: \.self) {
                    key in
                    if let observation = trackedObservations[key] {
                        // Renormalize detection frames to the bounds of the video frame
                        let box = VNImageRectForNormalizedRect(observation.boundingBox, Int(bounds.size.width), Int(bounds.size.height))
                        // Inner ZStack to encapsulate frame and confidence label text
                        ZStack {
                            Rectangle()
                                .strokeBorder(Color.green, style: StrokeStyle(lineWidth: 3.0))
                        }
                            .padding(10.0)
                            // Set the size and position of the view to those of the observation frame
                            .frame(width: box.size.width, height: box.size.height)
                            .position(x: box.origin.x + box.size.width * 0.5, y: bounds.size.height - (box.origin.y + box.size.height * 0.5))
                        Text(observation.uuid.uuidString)
                            .foregroundColor(Color.green)
                            .position(x: box.origin.x + box.size.width * 0.5, y: bounds.size.height - box.origin.y + 5.0)
                    }
                }
            }
                .blendMode(SwiftUI.BlendMode.hardLight)
                // When the nsImage changes, recalculate the bounds rectangle
                .onChange(of: nsImage) { img in
                        bounds = adjustedBounds(img.size, g.size)
                    }
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
struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
*/
