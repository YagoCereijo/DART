//
//  Level.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 12/8/22.
//

import Foundation
import UIKit
import CoreMotion

class LevelView: UIView, CAAnimationDelegate {
    
    
    // MARK: VARIABLES
    let circleA = CAShapeLayer()
    let circleB = CAShapeLayer()
    
    private let queue = OperationQueue()
    private let motionManager = CMMotionManager()
    private let PI_2 = Double.pi/2
   
    // MARK: PROPERTIES
    
    
    // MARK: FUNCTIONS
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = .clear
        self.layer.cornerRadius = layer.frame.width / 2
        self.clipsToBounds = false
        setupView()
    }
    
    func setupView(){
        let middle = self.layer.frame.width/2
        circleA.path = UIBezierPath(arcCenter: CGPoint(x:middle,y: middle), radius: 10, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        circleA.fillColor = UIColor.init(named: "green")?.cgColor


        circleB.path = UIBezierPath(arcCenter: CGPoint(x:middle,y: middle), radius: 10, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        circleB.fillColor = UIColor.init(named: "red")?.cgColor
      
        
        self.layer.addSublayer(circleA)
        self.layer.addSublayer(circleB)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.deviceMotionUpdateInterval = 1/60
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: { (data, error) in
                if let validData = data {

                    let pitch = validData.attitude.pitch
                    let roll = validData.attitude.roll
                    
                        self.moveCircle(circle: self.circleA, newPosition: self.getPointA(pitch, roll))
                    
                   
                        self.moveCircle(circle: self.circleB, newPosition: self.getPointB(pitch, roll))
                }
            })

        }else{print("Device Motion not available")}
    }
    
    
    func getPointA(_ pitch: Double, _ roll: Double)->CGPoint {
        
        let nPitch = pitch / PI_2
        let nRoll = roll / PI_2
        
        return CGPoint(x: nRoll, y: nPitch)
    }
    
    func getPointB(_ pitch: Double, _ roll: Double)->CGPoint {
        let point = getPointA(pitch, roll)
        return CGPoint(x: -point.x ,y: -point.y)
    }
    
    func moveCircle(circle: CAShapeLayer, newPosition: CGPoint){
        let point = CGPoint(x: newPosition.x*self.frame.width, y: newPosition.y*self.frame.width)
        let distance = sqrt(pow(point.x, 2) + pow(point.y, 2))
        let maxDistance = self.frame.width/2 - 10
        
        if distance < maxDistance {
            circle.position = point
        }
    }
}
