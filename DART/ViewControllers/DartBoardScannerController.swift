//
//  DartBoardScannerController.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 9/8/22.
//

import Foundation
import UIKit
import Vision
import SpriteKit

class DartBoardScannerController: UIViewController, ScannerViewDelegate, CAAnimationDelegate{
    
    // MARK: Variables
   

    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var scannerView: ScannerView!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var dartboardImage: UIImageView!
    
    
    var gameData: GameData!
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameData.refImage = CIImage(image: UIImage(named: "ref")!)!.resizeToSquareFilter(size: 600)
        scannerView.delegate = self
    }
    
    func matchFound(image: CIImage) {
        
        gameData.targetImage = alignAndCropImage(gameData.refImage, image)!
        dartboardImage.image = UIImage(ciImage: gameData.targetImage)
        
        let frameLayer = CAShapeLayer()
        frameLayer.frame = CGRect(x: 0, y: 0, width: dartboardImage.frame.width, height: dartboardImage.frame.width)
        frameLayer.backgroundColor = CGColor(red: 45/255, green: 41/255, blue: 38/255, alpha: 0.9)
        frameLayer.cornerRadius = 10
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: dartboardImage.frame.width, height: dartboardImage.frame.width)
        let size: CGFloat = (dartboardImage.frame.width - 20)
        let rect = CGRect(x: 10, y: 10, width: size, height: size)
        let circlePath = UIBezierPath(ovalIn: rect)
        let path = UIBezierPath(rect: dartboardImage.bounds)
        path.append(circlePath)
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.path = path.cgPath
        frameLayer.mask = maskLayer
        
        dartboardImage.layer.addSublayer(frameLayer)
        
        dartboardImage.isHidden = false
        controlsView.isHidden = false
        scannerView.isHidden = true
        

        
    }
    
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        performSegue(withIdentifier: "01", sender: nil)
    }
    
    @IBAction func reScan(_ sender: Any) {
        scannerView.resumeRecording()
        scannerView.isHidden = false
        dartboardImage.isHidden = true
        controlsView.isHidden = false
    }
    
    @IBAction func acceptBackground(_ sender: Any) {
        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to:    CGPoint(x: self.view.layer.frame.width*0.2, y: self.view.layer.frame.height*0.50))
        checkmarkPath.addLine(to: CGPoint(x: self.view.layer.frame.width*0.4, y: self.view.layer.frame.height*0.60))
        checkmarkPath.addLine(to: CGPoint(x: self.view.layer.frame.width*0.8, y: self.view.layer.frame.height*0.40))

        let checkmarkShape = CAShapeLayer()
        checkmarkShape.path = checkmarkPath.cgPath
        checkmarkShape.strokeColor = UIColor.white.cgColor
        checkmarkShape.lineWidth = 15
        checkmarkShape.lineCap = .round
        checkmarkShape.lineJoin = .round
        checkmarkShape.fillColor = UIColor.clear.cgColor

        let circle = CAShapeLayer()
        let circlePath1 = UIBezierPath(arcCenter: scannerView.layer.position, radius: 1, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
        let circlePath2 = UIBezierPath(arcCenter: scannerView.layer.position, radius: 700, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
        circle.path = circlePath2.cgPath
        circle.fillColor = UIColor(named: "green")?.cgColor

        self.view.layer.addSublayer(circle)
        self.view.layer.addSublayer(checkmarkShape)

        let scaleAnimation = CABasicAnimation(keyPath: "path")
        scaleAnimation.beginTime = CACurrentMediaTime()
        scaleAnimation.duration = 0.1
        scaleAnimation.fromValue = circlePath1.cgPath
        scaleAnimation.toValue = circlePath2.cgPath

        let checkmarkAnimation = CABasicAnimation(keyPath: "strokeEnd")
        scaleAnimation.beginTime = CACurrentMediaTime() + 0.5
        checkmarkAnimation.duration = 0.8
        checkmarkAnimation.fromValue = 0
        checkmarkAnimation.toValue = 4
        checkmarkAnimation.delegate = self

        checkmarkShape.add(checkmarkAnimation, forKey: "checkmark")
        circle.add(scaleAnimation, forKey: "scale")
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "01" {
            let view = segue.destination as! Controller01
            view.gameData = gameData
        }
    }
    
}

