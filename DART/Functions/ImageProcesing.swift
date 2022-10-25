//
//  ImageProcesing.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 8/8/22.
//

import Foundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins



func alignAndCropImage(_ reference:CIImage, _ test:CIImage) -> CIImage?{
    
    //Create the request handler, the one that respond to the request
    let imageRequestHandler = VNImageRequestHandler(ciImage: reference)
    
    //Create a request for a homographic alignment
    let request = VNHomographicImageRegistrationRequest(targetedCIImage: test)
    
    //Ask the handler to perform the request
    do{ try imageRequestHandler.perform([request])}
    catch { print(error.localizedDescription) }
    
    guard let results = request.results?.first as? VNImageHomographicAlignmentObservation else {return nil}
    
    let transform = results.warpTransform
    let quad = makeWarpedQuad(for: test.extent, using: transform)
    
    // Creates the alignedImage by warping the floating image using the warpTransform from the homographic observation.
    let transformParameters = [
        "inputTopLeft": CIVector(cgPoint: quad.topLeft),
        "inputTopRight": CIVector(cgPoint: quad.topRight),
        "inputBottomRight": CIVector(cgPoint: quad.bottomRight),
        "inputBottomLeft": CIVector(cgPoint: quad.bottomLeft)
    ]
    
    let alignedImage = test.applyingFilter("CIPerspectiveTransform", parameters: transformParameters)
    
    let cropFilter = CIFilter.blendWithMask()
    cropFilter.maskImage = CIImage(image: UIImage(named: "mask")!)!.resizeToSquareFilter(size: 600)
    cropFilter.inputImage = alignedImage
    cropFilter.backgroundImage = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 600, height: 600))
    let croppedImage = cropFilter.outputImage!
    
    return croppedImage
}



func alignImage(_ reference:CIImage, _ test:CIImage) -> CIImage?{
    
    //Create the request handler, the one that respond to the request
    let imageRequestHandler = VNImageRequestHandler(ciImage: reference)
    
    //Create a request for a homographic alignment
    let request = VNHomographicImageRegistrationRequest(targetedCIImage: test)
    
    //Ask the handler to perform the request
    do{ try imageRequestHandler.perform([request])}
    catch { print(error.localizedDescription) }
    
    guard let results = request.results?.first as? VNImageHomographicAlignmentObservation else {return nil}
    
    let transform = results.warpTransform
    let quad = makeWarpedQuad(for: test.extent, using: transform)
    
    // Creates the alignedImage by warping the floating image using the warpTransform from the homographic observation.
    let transformParameters = [
        "inputTopLeft": CIVector(cgPoint: quad.topLeft),
        "inputTopRight": CIVector(cgPoint: quad.topRight),
        "inputBottomRight": CIVector(cgPoint: quad.bottomRight),
        "inputBottomLeft": CIVector(cgPoint: quad.bottomLeft)
    ]
    
    let alignedImage = test.applyingFilter("CIPerspectiveTransform", parameters: transformParameters)
    
    return alignedImage
}

func cropImageCorners(ciImage:CIImage)->CIImage{
    
    let cropFilter = CIFilter.blendWithMask()
    cropFilter.maskImage = CIImage(image: UIImage(named: "mask")!)!
    cropFilter.inputImage = ciImage
    cropFilter.backgroundImage = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 600, height: 600))
    let croppedImage = cropFilter.outputImage!
    return croppedImage
}


private func warpedPoint(_ point: CGPoint, using warpTransform: simd_float3x3) -> CGPoint {
    let vector0 = SIMD3<Float>(x: Float(point.x), y: Float(point.y), z: 1)
    let vector1 = warpTransform * vector0
    return CGPoint(x: CGFloat(vector1.x / vector1.z), y: CGFloat(vector1.y / vector1.z))
}

private func makeWarpedQuad(for rect: CGRect, using warpTransform: simd_float3x3) -> Quad {
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY
    
    let topLeft = CGPoint(x: minX, y: maxY)
    let topRight = CGPoint(x: maxX, y: maxY)
    let bottomLeft = CGPoint(x: minX, y: minY)
    let bottomRight = CGPoint(x: maxX, y: minY)
    
    let warpedTopLeft = warpedPoint(topLeft, using: warpTransform)
    let warpedTopRight = warpedPoint(topRight, using: warpTransform)
    let warpedBottomLeft = warpedPoint(bottomLeft, using: warpTransform)
    let warpedBottomRight = warpedPoint(bottomRight, using: warpTransform)
    
    return Quad(topLeft: warpedTopLeft,
                topRight: warpedTopRight,
                bottomLeft: warpedBottomLeft,
                bottomRight: warpedBottomRight)
}



/// This is a quadrilateral defined by four corner points.
private struct Quad {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
}

extension CIImage {
    func resizeToSquareFilter(size: Float)->CIImage?{
        
        let resize = CIFilter.lanczosScaleTransform()
        resize.scale = size/Float(self.extent.height)
        resize.aspectRatio = size/(Float((self.extent.width)) * resize.scale)
        resize.inputImage = self
        let resizedImage = resize.outputImage!
        return resizedImage
    }
    
    func resizeToSquareAffineTransform(size: Double)->CIImage?{
        
        let scaleX = (size)/self.extent.width
        let scaleY = (size)/self.extent.height
        let image = self.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return image
    }

}





//        let scale = Float( size/Double(self.extent.height) )
//        let aspectRatio = Float( size/Double(self.extent.height)*scale )
//
//        let resize = CIFilter.lanczosScaleTransform()
//        resize.scale = Float(scale)
//        resize.aspectRatio = Float(aspectRatio)
//        resize.inputImage = self
//        return resize.outputImage
