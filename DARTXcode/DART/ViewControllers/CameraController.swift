import UIKit
import AVFoundation
import Vision
import CoreML

class CameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    //Create the capture session
    @IBOutlet weak var CameraCapturePreview: UIView!
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let imageView = UIImageView()
    
    var cameraLayer:AVCaptureVideoPreviewLayer!
    var rectangleList: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CameraCapturePreview.addSubview(imageView)
        let size: CGFloat = (self.view.frame.width-20)
        imageView.frame = CGRect(x: 10, y: 50, width: size, height: size)
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
            let blureffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
            let blurredEffectView = UIVisualEffectView(effect: blureffect)
            blurredEffectView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width , height: self.view.frame.height)
            
            CameraCapturePreview.layer.addSublayer(cameraLayer)
            CameraCapturePreview.addSubview(blurredEffectView)
        
            let maskLayer = CAShapeLayer()
            maskLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width , height: self.view.frame.width)
            // Create the frame for the circle.
            let size: CGFloat = (self.view.frame.width-20)
            // Rectangle in which circle will be drawn
            let rect = CGRect(x: 10, y: 50, width: size, height: size)
            let circlePath = UIBezierPath(ovalIn: rect)
            // Create a path
            let path = UIBezierPath(rect: view.bounds)
            // Append additional path which will create a circle
            path.append(circlePath)
            // Setup the fill rule to EvenOdd to properly mask the specified area and make a crater
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            // Append the circle to the path so that it is subtracted.
            maskLayer.path = path.cgPath
            blurredEffectView.layer.mask = maskLayer
            
            cameraLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width , height: self.view.frame.height)
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
        imageView.image = cropImage
        imageView.contentMode = .scaleAspectFit
        modelPredict(cropImage.cgImage!)
    }
    
    private func cropToPreviewLayer(originalImage: UIImage) -> UIImage? {
        
        guard let cgImage = originalImage.cgImage else { return nil }
        // MARK: Check how to properly access that CGRect that should be one of the circleLayerProperties
        let outputRect = cameraLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: 10,
                                                                                       y: 50,
                                                                                       width: self.view.frame.width-20,
                                                                                       height: self.view.frame.width-20))

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
    
    func modelPredict(_ image: CGImage){
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
        
        let dartDetectionRequest = VNCoreMLRequest(model: dartVNModel, completionHandler: { (request, error) in
            DispatchQueue.main.async(execute: {
                // perform all the UI updates on the main queue
                if let results = request.results {
                    print(results)
                    self.drawRects(results)
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
    
    func drawRects(_ results: [VNObservation]){
        for rectangle in rectangleList{
            rectangle.removeFromSuperview()
        }
        self.rectangleList = []
        let scorePredictorModel = scorePredictor()
        
        let width:CGFloat = CameraCapturePreview.frame.width - 20
        let height:CGFloat = CameraCapturePreview.frame.width - 20
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            //print(objectObservation.boundingBox, objectObservation.confidence)
            //print(width as Any, height as Any)
            let c = objectObservation.boundingBox
            let b = UIButton(frame:CGRect(x: (c.minX * width)+10, y: ((1-c.maxY) * height) + 50, width: c.width * width, height: c.height * height))
            b.layer.borderWidth = 2
            b.layer.cornerRadius = 5
            b.layer.borderColor = CGColor(red: 0, green: 148/255, blue: 115/255, alpha: 1)
           // b.translatesAutoresizingMaskIntoConstraints = false
            self.rectangleList.append(b)
            let result = try? scorePredictorModel.prediction(x: c.midX, y: 1-c.midY, width: c.width, height: c.height)
            guard let namePosition = result?.result else{return}
            b.setTitle(resultPrint(x: Int(namePosition)),for: .normal)
            b.setTitleColor(UIColor(cgColor: CGColor(red: 0, green: 148/255, blue: 115/255, alpha: 1)), for: .normal)
            b.titleLabel?.font = UIFont(name: "WTWagner", size: 15)
        }
        
        for rectangle in rectangleList{
            CameraCapturePreview.addSubview(rectangle)
        }
    }
    
    func resultPrint(x:Int)->String{
        let resultName = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "1 D", "2 D", "3 D", "4 D", "5 D", "6 D", "7 D", "8 D", "9 D", "10 D", "11 D", "12 D", "13 D", "14 D", "15 D", "16 D", "17 D", "18 D", "19 D", "20 D","1 T", "2 T", "3 T", "4 T", "5 T", "6 T", "7 T", "8 T", "9 T", "10 T", "11 T", "12 T", "13 T", "14 T", "15 T", "16 T", "17 T", "18 T", "19 T", "20 T","bullseye", "double bullseye"]
        
        return resultName[x]
    }
    
    
    
}
