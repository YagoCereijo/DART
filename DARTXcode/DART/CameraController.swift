import UIKit
import AVFoundation
import Vision
import CoreML

class CameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    private let photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var imageView:UIImageView?
    
    @IBOutlet weak var videoPreviewContainer: UIView!
    @IBOutlet weak var rectangleContainer: UIView!
    var rectangleList: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView = (rectangleContainer.viewWithTag(2) as? UIImageView)
        openCamera()
    }
    
    private func openCamera() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // the user has already authorized to access the camera.
                self.setupCaptureSession()
                
            case .notDetermined: // the user has not yet asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { (granted) in
                    if granted { // if user has granted to access the camera.
                        print("the user has granted to access the camera")
                        DispatchQueue.main.async {
                            self.setupCaptureSession()
                        }
                    } else {
                        print("the user has not granted to access the camera")
                        self.handleDismiss()
                    }
                }
                
            case .denied:
                print("the user has denied previously to access the camera.")
                self.handleDismiss()
                
            case .restricted:
                print("the user can't give camera access due to some restriction.")
                self.handleDismiss()
                
            default:
                print("something has wrong due to we can't access the camera.")
                self.handleDismiss()
            }
        }
    @objc private func handleDismiss() {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    
    private func setupCaptureSession() {
            let captureSession = AVCaptureSession()
            
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
                
                let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                cameraLayer.frame = CGRect(x: 0, y: 0, width: 414, height: 414)
                print(cameraLayer.frame)
                cameraLayer.videoGravity = .resizeAspectFill
                videoPreviewContainer.layer.addSublayer(cameraLayer)
                captureSession.startRunning()
            }
    }
    
    @IBAction func capturePhoto(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        print("capture photo")
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageCG = photo.cgImageRepresentation() else { return }
        
        let cropZone = CGRect(x: imageCG.width/4-60, y: 0, width: imageCG.height, height: imageCG.height)
        guard let cropImage = imageCG.cropping(to: cropZone) else { return }
        let imageUI = UIImage(cgImage: cropImage, scale: 1.0, orientation: .right)
        imageView!.image = imageUI
        
        let defaultConfig = MLModelConfiguration()
        let dartModel = try? myModel(configuration: defaultConfig)
        let dartVNModel:VNCoreMLModel
        
        do{
            dartVNModel = try VNCoreMLModel(for: dartModel!.model)
        }catch{
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        var requests : [VNRequest] = []
        let imageRequest = VNImageRequestHandler(cgImage: cropImage, orientation: .right)
        
        let dartDetectionRequest = VNCoreMLRequest(model: dartVNModel, completionHandler: { (request, error) in
            DispatchQueue.main.async(execute: {
                // perform all the UI updates on the main queue
                if let results = request.results {
                    //print(results)
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
    
    func drawRects(_ results: [Any]){
        
        for rectangle in rectangleList{
            rectangle.removeFromSuperview()
        }
        self.rectangleList = []
        let scorePredictorModel = scorePredictor()
        
        let width:CGFloat = rectangleContainer.frame.width
        let height:CGFloat = rectangleContainer.frame.height
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            //print(objectObservation.boundingBox, objectObservation.confidence)
            //print(width as Any, height as Any)
            let c = objectObservation.boundingBox
            let b = UIButton(frame:CGRect(x: c.minX * width, y: (1-c.maxY) * height, width: c.width * width, height: c.height * height))
            b.layer.borderWidth = 2
            b.layer.cornerRadius = 5
            b.layer.borderColor = UIColor.systemBlue.cgColor
           // b.translatesAutoresizingMaskIntoConstraints = false
            self.rectangleList.append(b)
            let result = try? scorePredictorModel.prediction(x: c.midX, y: 1-c.midY, width: c.width, height: c.height)
            guard let namePosition = result?.result else{return}
            b.setTitle(resultPrint(x: Int(namePosition)),for: .normal)
            b.setTitleColor(.systemBlue, for: .normal)
        }
        
        for rectangle in rectangleList{
            self.rectangleContainer.addSubview(rectangle)
        }
    }
    
    func resultPrint(x:Int)->String{
        let resultName = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "1 D", "2 D", "3 D", "4 D", "5 D", "6 D", "7 D", "8 D", "9 D", "10 D", "11 D", "12 D", "13 D", "14 D", "15 D", "16 D", "17 D", "18 D", "19 D", "20 D","1 T", "2 T", "3 T", "4 T", "5 T", "6 T", "7 T", "8 T", "9 T", "10 T", "11 T", "12 T", "13 T", "14 T", "15 T", "16 T", "17 T", "18 T", "19 T", "20 T","bullseye", "double bullseye"]
        
        return resultName[x]
    }
}
    
