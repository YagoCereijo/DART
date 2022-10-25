//
//  CameraView.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 12/8/22.
//

import Foundation
import UIKit
import AVFoundation
import Vision

protocol CameraViewDelegate: AnyObject{
    func imageCaptured(image: CIImage)
}

class CameraView: UIView, AVCapturePhotoCaptureDelegate{
    
    // MARK: VARIABLES
    
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    
    weak var delegate: CameraViewDelegate?
    var CameraLayer = AVCaptureVideoPreviewLayer()

    
    // MARK: FUNCTIONS
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCaptureSession()
    }
    
    

    private func processCapturedImage(image: CGImage)->CIImage?{
       
        //Crop the image to what is viewed in the CameraLayer
        let outputRect = CameraLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: 10, y: 10, width: self.layer.frame.width - 20, height: self.layer.frame.width - 20))

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        
        let cropRect = CGRect(x: outputRect.origin.x * width,
                              y: outputRect.origin.y * height,
                              width: outputRect.size.width * width,
                              height: outputRect.size.height * height)
         
        if let croppedCGImage = image.cropping(to: cropRect) {
            let ciImage = CIImage(cgImage: croppedCGImage).oriented(.right).resizeToSquareFilter(size: 300)!
            return ciImage
        }else{
            return nil
        }
    }
    
   
    private func setupCaptureSession(){
       
        captureSession = AVCaptureSession()
        let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession!.canAddInput(videoDeviceInput)
            else { return }
        captureSession!.addInput(videoDeviceInput)
        
        photoOutput = AVCapturePhotoOutput()
        guard captureSession!.canAddOutput(photoOutput) else { return }
    
        captureSession!.sessionPreset = .photo
        captureSession!.addOutput(photoOutput)
        captureSession!.commitConfiguration()
        
        CameraLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        CameraLayer.cornerRadius = 10
        
        let frameLayer = CAShapeLayer()
        frameLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        frameLayer.backgroundColor = CGColor(red: 45/255, green: 41/255, blue: 38/255, alpha: 0.9)
        frameLayer.cornerRadius = 10
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        let size: CGFloat = (self.frame.width - 20)
        let rect = CGRect(x: 10, y: 10, width: size, height: size)
        let circlePath = UIBezierPath(ovalIn: rect)
        let path = UIBezierPath(rect: self.bounds)
        path.append(circlePath)
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.path = path.cgPath
        frameLayer.mask = maskLayer
        
        CameraLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        CameraLayer.videoGravity = .resizeAspectFill
        CameraLayer.zPosition = -.greatestFiniteMagnitude
    
        let CameraLayerContainer = CALayer()
        CameraLayerContainer.addSublayer(CameraLayer)
        CameraLayerContainer.addSublayer(frameLayer)
        
        self.layer.addSublayer(CameraLayerContainer)
        
        captureSession!.startRunning()
        
        do{
            if (videoDevice.hasTorch){
                try videoDevice.lockForConfiguration()
                videoDevice.torchMode = .on
                videoDevice.unlockForConfiguration()
            }
        }catch{
            print("Device tourch Flash Error ");
        }

    }
    
    func takePhoto(){
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
                 
        let capturedImage = photo.cgImageRepresentation()
        let processedImage = processCapturedImage(image: capturedImage!)!
        captureSession.stopRunning()
        delegate?.imageCaptured(image: processedImage)
    }
    

}
