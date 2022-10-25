//
//  ObjectObservationsView.swift
//  SwiftVision
//
//  Created by Edward Janne on 10/24/22.
//

import SwiftUI
import AVFoundation
import CoreML
import Vision

struct ObjectObservationsView: View {
    @Binding var nsImage: NSImage
    @Binding var objectObservations: [VNRecognizedObjectObservation]
    @State var bounds: CGRect = .zero
    
    var body: some View {
        GeometryReader {
            g in
            ZStack {
                ForEach(objectObservations, id: \.uuid) {
                    observation in
                    
                    // Scale detection frames to the bounds of the video frame
                    let box = VNImageRectForNormalizedRect(observation.boundingBox, Int(bounds.size.width), Int(bounds.size.height))
                    ZStack {
                        Rectangle()
                            .strokeBorder(Color.red, style: StrokeStyle(lineWidth: 3.0))
                            .frame(width: box.size.width, height: box.size.height)
                            .position(x: box.origin.x + box.size.width * 0.5, y: bounds.size.height - (box.origin.y + box.size.height * 0.5))
                    }
                }
                Rectangle()
                    .strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0))
            }
                .clipped()
                .onChange(of: nsImage) { img in
                        bounds = adjustedBounds(img.size, g.size)
                    }
                .frame(width: bounds.size.width, height: bounds.size.height)
                .position(x: bounds.origin.x + bounds.size.width * 0.5, y: bounds.origin.y + bounds.size.height * 0.5)
        }
    }
    
    func adjustedSize(_ src: CGSize, _ dst: CGSize)->CGSize {
        if src.width / src.height <= dst.width / dst.height {
            return CGSize(width: src.width * dst.height / src.height, height: dst.height)
        }
        return CGSize(width: dst.width, height: src.height * dst.width / src.width)
    }
    
    func adjustedBounds(_ src: CGSize, _ dst: CGSize)->CGRect {
        let size = adjustedSize(src, dst)
        return CGRect(origin: CGPoint(x: (dst.width - size.width) * 0.5, y: (dst.height - size.height) * 0.5), size: size)
    }
}

/*
struct ObjectObservationsView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectObservationsView()
    }
}
*/
