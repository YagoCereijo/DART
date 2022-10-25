//
//  CameraView.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 7/8/22.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import CoreMotion

protocol ScannerViewDelegate: AnyObject{
    func matchFound(image: CIImage)
}

class ScannerView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    
    // MARK: VARIABLES
    
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice!
    private let context = CIContext()
    private var levelRatio: Double = 0
    private let queue = OperationQueue()
    private var motionManager = CMMotionManager()
    private let PI_2 = Double.pi/2
    private let SQRT2 = sqrt(2)
    private let circleA = CAShapeLayer()
    private let circleB = CAShapeLayer()
    var CameraLayer = AVCaptureVideoPreviewLayer()
    weak var delegate: ScannerViewDelegate?
    private var size: CGFloat!
    private var cropRect: CGRect!
    private var currentFrame: CIImage?
    
    // MARK: PROPERTIES

//    lazy var dartboardBB:CAShapeLayer = {
//        let _dartboardBB = CAShapeLayer()
//        _dartboardBB.fillColor = UIColor.clear.cgColor
//        _dartboardBB.lineJoin = .round
//        _dartboardBB.lineWidth = 2
//        _dartboardBB.strokeColor = UIColor.init(named: "green")?.cgColor
//        return _dartboardBB
//    }()
    
    lazy var meterLayer:CAShapeLayer = {
        var _meterLayer = CAShapeLayer()
        _meterLayer.position = CGPoint(x: self.layer.frame.width/2, y: self.layer.frame.height/2)
        _meterLayer.fillColor = UIColor.clear.cgColor
        _meterLayer.strokeColor = UIColor(named: "green")?.cgColor
        _meterLayer.masksToBounds = false
        _meterLayer.opacity = 1
        _meterLayer.lineCap = .round
        _meterLayer.lineWidth = 5
        _meterLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y:0), radius: meterRadius + _meterLayer.lineWidth/2, startAngle: 3*CGFloat.pi/2, endAngle: 7*CGFloat.pi/2, clockwise: true).cgPath
        _meterLayer.strokeEnd = 0
        
        return _meterLayer
    }()
    
    lazy var dartboardDetectorModel: VNCoreMLModel = {
        let defaultConfig = MLModelConfiguration()
        let dartboardDetector: DartboardDetector
        let dartboardDetectorModel:VNCoreMLModel
        
        do {
            dartboardDetector = try DartboardDetector(configuration: defaultConfig)
            dartboardDetectorModel = try VNCoreMLModel(for: dartboardDetector.model)}
        catch { fatalError("Error creating the dart detection model") }
    
        return dartboardDetectorModel
    }()
    
    lazy var meterRadius:CGFloat = {
        return self.layer.frame.width/2 - 10
    }()
    
    
    // MARK: FUNCTIONS
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCaptureSession()
        setupLevel()
        size = self.layer.frame.width
        
        let outputRect = CameraLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: 0, y: 0, width: size, height: size))
        
        let imageWidth: CGFloat = 1920
        let imageHeight: CGFloat = 1080
        
        cropRect = CGRect(x: outputRect.origin.x * imageWidth,
                              y: outputRect.origin.y * imageHeight,
                              width: outputRect.size.width * imageWidth,
                              height: outputRect.size.height * imageHeight)
        
        //self.layer.addSublayer(dartboardBB)
    }
    
    func setupLevel(){
        let middle = self.layer.frame.width/2
        circleA.path = UIBezierPath(arcCenter: CGPoint(x:middle,y: middle), radius: 10, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        circleA.fillColor = UIColor.init(named: "green")?.cgColor


        circleB.path = UIBezierPath(arcCenter: CGPoint(x:middle,y: middle), radius: 10, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        circleB.fillColor = UIColor.init(named: "red")?.cgColor
      
        
        self.layer.addSublayer(circleA)
        self.layer.addSublayer(circleB)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.deviceMotionUpdateInterval = 1/30
            motionManager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: { (data, error) in
                if let validData = data {

                    let pitch = validData.attitude.pitch
                    let yaw = validData.attitude.yaw
                    self.levelRatio = abs(pitch/self.PI_2)
                
                    DispatchQueue.main.async {
                        self.moveCircleA(pitch: pitch, yaw: yaw)
                        self.moveCircleB(pitch: pitch, yaw: yaw)
                    }
                }
            })

        }else{print("Device Motion not available")}
    }
    
        
    func moveCircleA(pitch:Double, yaw: Double){
        
        let positionX = cos(yaw) * (1 - abs(pitch/PI_2))
        let positionY = sin(yaw) * (1 - abs(pitch/PI_2))
        
        moveCircle(positionX, positionY, circleA)
        
    }
    
    func moveCircleB(pitch:Double, yaw: Double){
        
        let positionX = cos(yaw) * (-(1 - abs(pitch/PI_2)))
        let positionY = sin(yaw) * (-(1 - abs(pitch/PI_2)))
        
        moveCircle(positionX, positionY, circleB)
    }
    
    func moveCircle(_ positionX: Double, _ positionY: Double, _ circle: CAShapeLayer){
        let maxRadius = self.frame.width/2 - 10
        
        let point = CGPoint(x: (positionX * maxRadius),
                            y: (positionY * maxRadius))
        
        
        circle.position = point
    }
    
    
    internal func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        let image = processFrame(image: cgImage)
        if image != nil { self.delegate?.matchFound(image: image!)}
    }
    

    private func processFrame(image: CGImage)->CIImage?{
        if let croppedCGImage = image.cropping(to: cropRect) {
            let ciImage = CIImage(cgImage: croppedCGImage).oriented(.right)
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage)
            let dartboardDetectionRequest = VNCoreMLRequest(model: dartboardDetectorModel)
            
            do {
                try imageRequestHandler.perform([dartboardDetectionRequest])
                DispatchQueue.main.async { [self] in
                    if let results = dartboardDetectionRequest.results {
                        if !results.isEmpty{
                            guard let objectObservation = results.first! as? VNRecognizedObjectObservation else { return}
                            if computeSimilarity(observation: objectObservation) {
                                delegate?.matchFound(image: ciImage.resizeToSquareAffineTransform(size: 600)!)
                                stopRecording()
                                
                            }
                        }else{
                            if self.meterLayer.animation(forKey: "strokeEnd") == nil {
                                let animation = CABasicAnimation(keyPath: "strokeEnd")
                                animation.fromValue = self.meterLayer.strokeEnd
                                animation.toValue = 0
                                animation.duration = 1
                                animation.fillMode = .forwards
                                animation.isRemovedOnCompletion = false
                                self.meterLayer.add(animation, forKey: "strokeEnd")
                                //self.dartboardBB.path = nil
                            }
                        }
                    }
                }
            }
            catch { fatalError("Failed to perform image request: \(error)")}
            
            return nil
        }else{
            return nil
        }
    }
    
    private func computeSimilarity(observation: VNRecognizedObjectObservation)->Bool{
        
                
        let bb = observation.boundingBox
        let bbFrame =  CGRect(x: bb.minX * size, y: (1-bb.maxY) * size, width: bb.width * size, height: bb.height * size )
        //dartboardBB.path = CGPath(rect: bbFrame, transform: nil)
        
        //Detection properties analisys
        let aspectRatio = 1 - abs(1-bb.width/bb.height) // [0...1]
        var sizeRatio = sqrt(pow(bb.width,2) + pow(bb.height, 2)) / SQRT2 // [0...1]
        let centeredRatio = 1 - sqrt(pow(bb.minX, 2) + pow(1-bb.maxY, 2)) / SQRT2 // [0...1]
        
        if sizeRatio > 1 { sizeRatio = 1}
        
        let strokeEnd = sizeRatio * 0.2 + centeredRatio * 0.50 + levelRatio * 0.05 + aspectRatio * 0.25
        
        meterLayer.strokeEnd = strokeEnd
        if strokeEnd > 0.95 { stopRecording(); return true }
        else { return false }
    }
    
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
    
    
    private func setupCaptureSession(){
       
        captureSession = AVCaptureSession()
        videoDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession!.canAddInput(videoDeviceInput)
            else { return }
        captureSession!.addInput(videoDeviceInput)
        
        let frameOutput = AVCaptureVideoDataOutput()
        guard captureSession!.canAddOutput(frameOutput) else { return }
        frameOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        captureSession!.sessionPreset = .hd1920x1080
        captureSession!.addOutput(frameOutput)
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
    
        let CameraLayerContainer = CALayer()
        CameraLayerContainer.addSublayer(CameraLayer)
        CameraLayerContainer.addSublayer(frameLayer)
        
        self.layer.addSublayer(CameraLayerContainer)
        self.layer.addSublayer(meterLayer)
        
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
    
    func stopRecording(){
       
        do{
            if (videoDevice.hasTorch){
                try videoDevice.lockForConfiguration()
                videoDevice.torchMode = .off
                videoDevice.unlockForConfiguration()
            }
        }catch{
            print("Device tourch Flash Error ");
        }
        motionManager.stopDeviceMotionUpdates()
        captureSession?.stopRunning()
    }
    
    func resumeRecording(){
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue() , withHandler: { (data, error) in
            if let validData = data {

                let pitch = validData.attitude.pitch
                let yaw = validData.attitude.yaw
                print(pitch, yaw)
                self.levelRatio = 1 - abs((pitch + yaw)/Double.pi)
                
                DispatchQueue.main.async {
                    self.moveCircleA(pitch: pitch, yaw: yaw)
                    self.moveCircleB(pitch: pitch, yaw: yaw)
                }
            
                
            }
        })
        
        captureSession?.startRunning()
        
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
}
