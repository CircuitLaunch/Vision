//
//  FaceLandmarksView.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/25/22.
//

import SwiftUI
import Vision

struct FaceLandmarksView: View {
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
                    // Inner ZStack to encapsulate frame and confidence label text
                    ZStack {
                        // Create a list of landmarks per observation
                        let landmarks = collectLandmarks(fromFace: observation)
                        // Iterate through the landmarks
                        ForEach(0 ..< landmarks.count, id: \.self) {
                            i in
                            let region = landmarks[i]
                            // Render a path
                            generatePath(fromLandmarkRegion: region)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.0))
                        }
                    }
                }
            }
                .opacity(0.75)
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
    
    // Assembles the landmark regions (if any) attached to the VNFaceObservation
    // into an interatable list
    func collectLandmarks(fromFace face: VNFaceObservation)->[VNFaceLandmarkRegion2D] {
        if let landmarks = face.landmarks {
             return [
                landmarks.faceContour,
                landmarks.leftEye,
                landmarks.rightEye,
                landmarks.leftEyebrow,
                landmarks.rightEyebrow,
                landmarks.nose,
                landmarks.noseCrest,
                landmarks.medianLine,
                landmarks.outerLips,
                landmarks.innerLips,
                landmarks.leftPupil,
                landmarks.rightPupil].compactMap { region in region }
        }
        return []
    }
    
    // Generates a Path from the renormalized points of a landmark
    func generatePath(fromLandmarkRegion region: VNFaceLandmarkRegion2D)->Path {
        let pts = region.pointsInImage(imageSize: bounds.size).map {
            pt in
            CGPoint(x: pt.x, y: self.bounds.height - pt.y)
        }
        let path = CGMutablePath()
        if pts.count > 1 {
            path.move(to: pts[0])
            for i in 1 ..< pts.count {
                path.addLine(to: pts[i])
            }
        } else {
            path.move(to: pts[0])
            path.addArc(center: pts[0], radius: 1.0, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        }
        path.closeSubpath()
        return Path(path)
    }
}

/*
struct FaceLandmarksView_Previews: PreviewProvider {
    static var previews: some View {
        FaceLandmarksView()
    }
}
*/
