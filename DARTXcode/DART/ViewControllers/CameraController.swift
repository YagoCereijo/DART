import UIKit
import AVFoundation
import Vision
import CoreML
import SpriteKit

class CameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    //Create the capture session
    @IBOutlet weak var CameraCapturePreview: UIView!
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let imageView = UIImageView()
    
    var sceneView:SKView!
    var cameraLayer:AVCaptureVideoPreviewLayer!
    var rectangleList: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size: CGFloat = (self.view.frame.width*0.9-20)
        imageView.frame = CGRect(x: 10, y: 10, width: size, height: size)
        imageView.layer.cornerRadius = size/2
        imageView.clipsToBounds = true
        checkCameraPermission()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: self.setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted { DispatchQueue.main.async { self.setupCaptureSession()}}
            }
        case .denied: dismiss(animated: false)
        case .restricted: dismiss(animated: false)
        default: dismiss(animated: false)
        }
    }
    
    func setupCaptureSession(){
        if let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch let error {
                print("Failed to set input device with error: \(error)")
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.cornerRadius = 10
            
            let layer = CAShapeLayer()
            layer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.9 , height: self.view.frame.width * 0.9)
            layer.backgroundColor = CGColor(red: 45/255, green: 41/255, blue: 38/255, alpha: 0.9)
            layer.cornerRadius = 10
            
            
            CameraCapturePreview.layer.addSublayer(cameraLayer)
            CameraCapturePreview.layer.addSublayer(layer)
            CameraCapturePreview.addSubview(imageView)
        
            let maskLayer = CAShapeLayer()
            maskLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.9 , height: self.view.frame.width * 0.9)
            // Create the frame for the circle.
            let size: CGFloat = (self.view.frame.width * 0.9 - 20)
            // Rectangle in which circle will be drawn
            let rect = CGRect(x: 10, y: 10, width: size, height: size)
            let circlePath = UIBezierPath(ovalIn: rect)
            // Create a path
            let path = UIBezierPath(rect: view.bounds)
            // Append additional path which will create a circle
            path.append(circlePath)
            // Setup the fill rule to EvenOdd to properly mask the specified area and make a crater
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            // Append the circle to the path so that it is subtracted.
            maskLayer.path = path.cgPath
            layer.mask = maskLayer
            
            cameraLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.9 , height: self.view.frame.width * 0.9)
            cameraLayer.videoGravity = .resizeAspectFill
            captureSession.startRunning()
        }
    }
    
    @IBAction func TakePhoto(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        let imageData = photo.fileDataRepresentation()!
        let image = UIImage(data: imageData)!
        let cropImage = cropToPreviewLayer(originalImage: image)!
        //imageView.image = cropImage
        imageView.contentMode = .scaleAspectFit
        modelPredict(cropImage.cgImage!)
    }
    
    private func cropToPreviewLayer(originalImage: UIImage) -> UIImage? {
        
        guard let cgImage = originalImage.cgImage else { return nil }
        // MARK: Check how to properly access that CGRect that should be one of the circleLayerProperties
        let outputRect = cameraLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: 10,
                                                                                       y: 10,
                                                                                       width: self.view.frame.width * 0.9 - 20,
                                                                                       height: self.view.frame.width * 0.9 - 20))

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let cropRect = CGRect(x: outputRect.origin.x * width,
                              y: outputRect.origin.y * height,
                              width: outputRect.size.width * width,
                              height: outputRect.size.height * height)
         

        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: originalImage.imageOrientation)
        }

        return nil
    }
    
    private func modelPredict(_ image: CGImage){
        
        let defaultConfig = MLModelConfiguration()
        let dartModel = try? myModel(configuration: defaultConfig)
        let dartVNModel:VNCoreMLModel
        
        do{
            dartVNModel = try VNCoreMLModel(for: dartModel!.model)
        }catch{
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        var requests : [VNRequest] = []
        let imageRequest = VNImageRequestHandler(cgImage: image, orientation: .right)
        
        let scorePredictorModel = scorePredictor()
        
        let dartDetectionRequest = VNCoreMLRequest(model: dartVNModel, completionHandler: { (request, error) in
            DispatchQueue.main.async(execute: {
                // perform all the UI updates on the main queue
                if let results = request.results {
                    
                    var scoreResults:[String] = []
                    results.forEach{
                        let objectObservation = $0 as! VNRecognizedObjectObservation
                        let c = objectObservation.boundingBox
                        
                        let scoreResult = try? scorePredictorModel.prediction(x: c.midX, y: 1-c.midY, width: c.width, height: c.height)
                        guard let namePosition = scoreResult?.result else {return}
                        scoreResults.append(self.resultPrint(x: Int(namePosition)))
                    }
                    print(scoreResults)
                    self.sceneView = SKView()
                    let scene = DartSelectorScene(size: CGSize(width: self.CameraCapturePreview.frame.width*0.95, height: self.CameraCapturePreview.frame.height*0.95), results: scoreResults)
                    scene.scaleMode = SKSceneScaleMode.resizeFill
                    scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    self.sceneView.ignoresSiblingOrder = true
                    scene.backgroundColor = UIColor.clear
                    self.sceneView.presentScene(scene)
                    self.sceneView.translatesAutoresizingMaskIntoConstraints = false
                    self.sceneView.clipsToBounds = true
                    self.sceneView.layer.cornerRadius = self.CameraCapturePreview.frame.width*0.95/2
                    self.CameraCapturePreview.addSubview(self.sceneView)
                    NSLayoutConstraint.activate([
                        self.sceneView.centerXAnchor.constraint(equalTo: self.CameraCapturePreview.centerXAnchor),
                        self.sceneView.centerYAnchor.constraint(equalTo: self.CameraCapturePreview.centerYAnchor),
                        self.sceneView.widthAnchor.constraint(equalTo: self.CameraCapturePreview.widthAnchor, multiplier: 0.95),
                        self.sceneView.heightAnchor.constraint(equalTo: self.CameraCapturePreview.heightAnchor, multiplier: 0.95)
                    ])
                }
            })
        })
        
        requests.append(dartDetectionRequest)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequest.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
    
   
    func resultPrint(x:Int)->String{
        let resultName = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "1 D", "2 D", "3 D", "4 D", "5 D", "6 D", "7 D", "8 D", "9 D", "10 D", "11 D", "12 D", "13 D", "14 D", "15 D", "16 D", "17 D", "18 D", "19 D", "20 D","1 T", "2 T", "3 T", "4 T", "5 T", "6 T", "7 T", "8 T", "9 T", "10 T", "11 T", "12 T", "13 T", "14 T", "15 T", "16 T", "17 T", "18 T", "19 T", "20 T","bullseye", "doubleBullseye"]
        
        return resultName[x]
    }
    
    @objc func panButton(pan: UIPanGestureRecognizer) {
        let button = pan.view as! UIButton
        let location = pan.location(in: CameraCapturePreview) // get pan location
        button.center = location // set button to where finger is
    }
    
    
    @IBAction func RemoveSamplePhoto(_ sender: Any) {
        imageView.image = UIImage()
        rectangleList.forEach{$0.removeFromSuperview()}
        self.sceneView.removeFromSuperview()
    }
    
    
}
