import UIKit
import AVFoundation
import Vision
import CoreML
import SceneKit
import SpriteKit


class ScannerController: UIViewController, ScannerViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, ScoreSelectorSceneDelegate{
    
    @IBOutlet weak var scannerView: ScannerView!
    @IBOutlet weak var predictionView: UIImageView!
    @IBOutlet weak var scoreCollection: UICollectionView!
    @IBOutlet weak var scoreSelector: SKView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var swapButton: UIButton!
    
    @IBOutlet weak var reScan: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var exitButtonArrow: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    private var thresholdProvider = ThresholdProvider()
    
    private weak var sceneView:SCNView? = {
        var sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
        sceneView.scene = SCNScene(named: "dart.scn")!
        return sceneView
    }()
    
    lazy var dartDetectorModel: VNCoreMLModel = {
        let defaultConfig = MLModelConfiguration()
        let dartDetector: DartDetector
        let dartDetectorModel:VNCoreMLModel
        
        do {
            dartDetector = try DartDetector(configuration: defaultConfig)
            dartDetectorModel = try VNCoreMLModel(for: dartDetector.model)}
        catch { fatalError("Error creating the dart detection model") }
    
        return dartDetectorModel
    }()
    
    let PI_2 = Float.pi * 2
    var gameData: GameData!
    var scoreResults: [(score : String, boundingBox: CGRect)]!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scannerView.delegate = self
        scoreCollection.delegate = self
        scoreCollection.dataSource = self
    }
    
//    MARK: DELEGATE FUNCTIONS
    
    func matchFound(image: CIImage) {
        let alignedImage = alignAndCropImage(gameData.targetImage, image)!
        scoreResults = analizeScore(image: alignedImage)
        setupPredictionView(ciImage: alignedImage)
        setupScoreSelector()
        scoreCollection.reloadData()
        swapButton.isHidden = false
        scannerView.isHidden = true
        exitButton.isHidden = true
        exitButtonArrow.isHidden = false
        reScan.isHidden = false
        acceptButton.isHidden = false
        scoreCollection.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if scoreResults != nil {
            if scoreResults.count < 3 { return scoreResults.count+1 }
            else { return scoreResults.count }
        }else{ return 0 }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < scoreResults.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DartCell", for: indexPath) as! DartCell
            cell.result.text = scoreResults[indexPath.row].score
            return cell
        } else if indexPath.row <= scoreResults.count{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddDartCell", for: indexPath) as! AddDartCell
            cell.button.addTarget(self, action: #selector(addDart), for: .touchDown)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func dataChanged(atIndex index: Int, newScoreResult: (String, CGRect)) {
        scoreResults[index] = newScoreResult
        drawBoundingBoxes()
        scoreCollection.reloadData()
    }
    
    func dataAdded(newScoreResult: (String, CGRect)) {
        scoreResults.append(newScoreResult)
        drawBoundingBoxes()
        scoreCollection.reloadData()
    }
    
    @objc func addDart(){
        let scoreSelectorScene = scoreSelector.scene as! ScoreSelectorScene
        scoreSelectorScene.addDart()
    }
    
    
//  MARK: IMAGE ANALISIS
    
    func analizeScore(image: CIImage)->[(String, CGRect)]{
        let boundingBoxes = dartDetection(image: image)
        let tipPositions = tipPositionEstimation(boundingBoxes: boundingBoxes, originalImage: image)
        let puntuations = puntuationFromPositions(positions: tipPositions)
        return zip(puntuations, boundingBoxes).map({return ($0, $1)})
    }
    
    func dartDetection(image: CIImage)->[CGRect]{
        
        
        // Define threshold values. These could also be defined elsewhere in the code so that they can
        // be updated by the user.
        dartDetectorModel.featureProvider = thresholdProvider
        

        let imageRequestHandler = VNImageRequestHandler(ciImage: image)
        let dartDetectionRequest = VNCoreMLRequest(model: dartDetectorModel)
        var boundingBoxes = [CGRect]()
        
        
        do {
            try imageRequestHandler.perform([dartDetectionRequest])
            if let results = dartDetectionRequest.results {
                if !results.isEmpty{
                    if let objectObservations = results as? [VNRecognizedObjectObservation] {
                        for o in objectObservations{
                            boundingBoxes.append(o.boundingBox)
                        }
                    }
                }
            }
            
        }
        catch { fatalError("Failed to perform image request: \(error)")}
        
        
        return boundingBoxes
    }
    
    
    func tipPositionEstimation(boundingBoxes: [CGRect], originalImage: CIImage)->[SCNVector3]{
        
        func renderWithOrientation(tipPosition: SCNVector3, featherPosition: SCNVector3)->(CIImage, SCNVector3)?{
            dart.position = tipPosition
            dart.look(at: featherPosition, up: SCNVector3(0,0,0), localFront: SCNVector3(0,1,0))
            if let image = CIImage(image: sceneView!.snapshot() ) {
                return (image, tipPosition)
                
            }else {return nil}
        }
        let dart = sceneView!.scene!.rootNode.childNode(withName: "dart", recursively: true)!
        let dartBoard = sceneView!.scene!.rootNode.childNode(withName: "dartboard", recursively: true)!
        
        let ciContext = CIContext()
        let imageMaterial = ciContext.createCGImage(gameData.targetImage, from: gameData.targetImage.extent)
        dartBoard.geometry?.firstMaterial?.diffuse.contents = imageMaterial
        let material = dartBoard.geometry?.firstMaterial
        
        
        let dartHeight = (dart.boundingBox.max.y - dart.boundingBox.min.y) * dart.scale.y

        var tipPositions = [SCNVector3]()
        
        for b in boundingBoxes{
            
            let bbViewCoordinates = CGRect(x: b.minX * 600,
                                           y: 600 - b.maxY * 600,
                                           width: b.width * 600,
                                           height: b.height * 600)
            
            let max = sceneView!.unprojectPoint(SCNVector3(bbViewCoordinates.minX, bbViewCoordinates.minY, 1))
            let min = sceneView!.unprojectPoint(SCNVector3(bbViewCoordinates.maxX, bbViewCoordinates.maxY, 1))
            
            let width = max.x - min.x
            let height = max.y - min.y
            
            let mid = vector_float2(min.x + width/2,  min.y + height/2)
            
            //boundingBoxDiagonal (bbd)
            let bbd = sqrt(pow(height,2)+pow(width,2))
            
            //z position for the opposite extreme of the tip when tip and f
            let zPositionDiagonal = sqrt(pow(dartHeight,2) - pow(bbd,2))
            let zPositionStraight = sqrt(pow(dartHeight,2) - pow(height,2))
            let zPositionCenter = dartHeight
            
            // Known the size transform the original bounding box coordinates to the scene
            // adding a few relevant points
            //
            //    A    B    C
            //     +───+───+
            //     |       |
            //    H+  I+   +D
            //     |       |
            //     +───+───+
            //    G    F    E
            //
            
            let ptoA = vector_float2(min.x, max.y)
            let ptoB = vector_float2(mid.x, max.y)
            let ptoC = vector_float2(max.x, max.y)
            let ptoD = vector_float2(max.x, mid.y)
            let ptoE = vector_float2(max.x, min.y)
            let ptoF = vector_float2(mid.x, min.y)
            let ptoG = vector_float2(min.x, min.y)
            let ptoH = vector_float2(min.x, mid.y)
            let ptoI = vector_float2(mid.x, mid.y)
            
            // Get renders and the position of the tip in them
            var rawRenders = [(CIImage, SCNVector3)?]()
            // 1. DART ALONG DIAGONAL
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoA.x, ptoA.y, -1.25), featherPosition: SCNVector3(ptoE.x, ptoE.y, zPositionDiagonal)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoC.x, ptoC.y, -1.25), featherPosition: SCNVector3(ptoG.x, ptoG.y, zPositionDiagonal)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoE.x, ptoE.y, -1.25), featherPosition: SCNVector3(ptoA.x, ptoA.y, zPositionDiagonal)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoG.x, ptoG.y, -1.25), featherPosition: SCNVector3(ptoC.x, ptoC.y, zPositionDiagonal)))
            
            // 2. DART STRAIGHT TROUGHT THE MIDDLE
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoB.x, ptoB.y, -1.25), featherPosition: SCNVector3(ptoF.x, ptoF.y, zPositionStraight)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoF.x, ptoF.y, -1.25), featherPosition: SCNVector3(ptoB.x, ptoB.y, zPositionStraight)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoH.x, ptoH.y, -1.25), featherPosition: SCNVector3(ptoD.x, ptoD.y, zPositionStraight)))
            rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoD.x, ptoD.y, -1.25), featherPosition: SCNVector3(ptoH.x, ptoH.y, zPositionStraight)))
            
            // 3. DART IN THE MIDDLE
           rawRenders.append(renderWithOrientation(tipPosition: SCNVector3(ptoI.x, ptoI.y, 0), featherPosition: SCNVector3(ptoI.x, ptoI.y, zPositionCenter)))
            
            
            var winnerDistance = CGFloat.infinity
            var winner:(CIImage, SCNVector3) = (CIImage(), SCNVector3())
            var renderImage = [CIImage]()
            let ciContext = CIContext()
            
            for r in rawRenders{

                let image = r!.0
                
                renderImage.append(image)
                
                let diffFilter = CIFilter.colorAbsoluteDifference()
                diffFilter.inputImage = originalImage
                diffFilter.inputImage2 = alignAndCropImage(originalImage, image.resizeToSquareFilter(size: 600)!)
                let diff = diffFilter.outputImage!
                
                let averageColorFilter = CIFilter.areaAverage()
                averageColorFilter.inputImage = diff
                averageColorFilter.extent = diff.extent
                let averageColor = averageColorFilter.outputImage!

                let cgImage = ciContext.createCGImage(
                      averageColor,
                      from: averageColor.extent
                    )!

                let dataProvider = cgImage.dataProvider!
                let data = CFDataGetBytePtr(dataProvider.data)!
                let color = UIColor(red: CGFloat(data[0])/255,
                                    green: CGFloat(data[1])/255,
                                    blue: CGFloat(data[2])/255,
                                    alpha:  CGFloat(data[3])/255)
                
                let colorComponentsSum = CGFloat(data[0]) + CGFloat(data[1]) + CGFloat(data[2]) + CGFloat(data[3])
                
                if colorComponentsSum < winnerDistance {
                    winner = r!
                    winnerDistance = colorComponentsSum
                }
            }
            
            tipPositions.append(winner.1)
        }
        
        return tipPositions
    }
    
    func puntuationFromPositions(positions: [SCNVector3])->[String]{
        
        var puntuations = [String]()
        
        for position in positions {
            let regions = [ "6" ,"13", "4", "18", "1", "20", "5", "12", "9", "14", "11", "8", "16", "7", "19", "3", "17", "2", "15", "10"]
            var puntuation: String
            
            //Convert to polar coordinates
            let r = sqrt(pow(position.x, 2) + pow(position.y, 2))
            var a:Float!
            
            //The following measures where taken from the dartboard
            if r < 0.635        { puntuations.append( "⦿" ); break }
            else if r < 1.8     { puntuations.append( "⦾" ); break }
            else if r < 9.9     { puntuation = "" }
            else if r < 10.9    { puntuation = "T-" }
            else if r < 16.3    { puntuation = "" }
            else if r < 17      { puntuation = "D-" }
            else                { puntuations.append( "x" ); break }
                        
            
            if position.x > 0 && position.y >= 0        { a = atan(position.y/position.x)}
            else if position.x == 0 && position.y > 0   { a = Float.pi/2}
            else if position.x < 0                      { a = atan(position.y/position.x) + Float.pi}
            else if position.x == 0 && position.y < 0   { a = 3*Float.pi/2}
            else if position.x > 0 && position.y < 0    { a = atan(position.y/position.x) + PI_2}
            
            for (b, index) in zip(stride(from: -PI_2/40, to: PI_2-PI_2/40, by: PI_2/20), 0...19){
                if b <= a && a < b+PI_2/20 { puntuations.append(puntuation + regions[index]); break }
            }
        }
        
        return puntuations
    }
    
//  MARK: PREDICTION VIEW
    
    func setupPredictionView(ciImage: CIImage){
        predictionView.image = UIImage(ciImage: ciImage)
        predictionView.layer.cornerRadius = predictionView.layer.frame.width / 2
        predictionView.contentMode = .scaleAspectFit
        predictionView.isHidden = false
        drawBoundingBoxes()
    }
    
    
    func drawBoundingBoxes(){
        
        predictionView.layer.sublayers?.removeAll()
        
        for score in scoreResults{
            
            let b = score.boundingBox
            
            let adjustedBoundingBox = CGRect(x: b.minX * predictionView.layer.frame.width,
                                             y: predictionView.layer.frame.height - b.maxY * predictionView.layer.frame.height,
                                             width: b.width * predictionView.layer.frame.width,
                                             height: b.height * predictionView.layer.frame.height)
            
            let boundingBoxPath = CGPath(rect: adjustedBoundingBox, transform: nil)
            
            let boundingBoxShape = CAShapeLayer()
            boundingBoxShape.path = boundingBoxPath
            boundingBoxShape.fillColor = UIColor.clear.cgColor
            boundingBoxShape.lineJoin = .round
            boundingBoxShape.lineWidth = 2
            boundingBoxShape.strokeColor = UIColor.init(named: "green")?.cgColor
            
            predictionView.layer.addSublayer(boundingBoxShape)
            
        }
    }
    
//  MARK: SCORE SELECTOR
    
    func setupScoreSelector(){
        scoreSelector.allowsTransparency = true
        let scene = ScoreSelectorScene(size: containerView.layer.frame.size)
        scene.results = scoreResults.map{return $0.score}
        scene.scoreSelectorDelegate = self
        scoreSelector.clipsToBounds = false
        scoreSelector.presentScene(scene)
        scoreCollection.reloadData()
    }
    
//  MARK: VIEW SWAPPER
    @IBAction func swapView(_ sender: Any) {
       
        if scoreSelector.isHidden {
            swapButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle"), for: .normal)
        }else if predictionView.isHidden{
            swapButton.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        }
        
        scoreSelector.isHidden = !scoreSelector.isHidden
        predictionView.isHidden = !predictionView.isHidden
        
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: nil, completion: nil)
        
    }
    
    //  MARK: RESCAN
    
    @IBAction func reScan(_ sender: Any) {
        scoreResults.removeAll()
        scoreCollection.reloadData()
        exitButton.isHidden = false
        exitButtonArrow.isHidden = true
        reScan.isHidden = true
        acceptButton.isHidden = true
        scoreSelector.isHidden = true
        predictionView.isHidden = true
        scannerView.isHidden = false
        swapButton.isHidden = true
        scoreCollection.isHidden = true
        scannerView.resumeRecording()
    }
    
}




class ThresholdProvider: MLFeatureProvider {
    //IoU default = 0.45
    //Cofidence default = 0.25
    open var values = [
        "iouThreshold": MLFeatureValue(double: 0.45),
        "confidenceThreshold": MLFeatureValue(double: 0.1)
    ]

    /// The feature names the provider has, per the MLFeatureProvider protocol
    var featureNames: Set<String> {
        return Set(values.keys)
    }

    /// The actual values for the features the provider can provide
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return values[featureName]
    }
}
