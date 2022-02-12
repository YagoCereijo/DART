//
//  DartSelectorScene.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 3/2/22.
//

import SpriteKit
import GameplayKit

typealias Radians = CGFloat

extension UIBezierPath {

    static func simonWedge(innerRadius: CGFloat, outerRadius: CGFloat, centerAngle: Radians, gap: CGFloat) -> UIBezierPath {
        let innerAngle: Radians = CGFloat.pi / 20 - gap / (2 * innerRadius)
        let outerAngle: Radians = CGFloat.pi / 20 - gap / (2 * innerRadius)
        let path = UIBezierPath()
        path.addArc(withCenter: .zero, radius: innerRadius, startAngle: centerAngle - innerAngle, endAngle: centerAngle + innerAngle, clockwise: true)
        path.addArc(withCenter: .zero, radius: outerRadius, startAngle: centerAngle + outerAngle, endAngle: centerAngle - outerAngle, clockwise: false)
        path.close()
        return path
    }

}

class DartSelectorScene: SKScene, SKPhysicsContactDelegate {
    
    
    let red = UIColor(named: "red") ?? .red
    let green = UIColor(named: "green") ?? .green
    let white = UIColor(named: "white") ?? .white
    let black = UIColor(named: "black") ?? .black
    let dartNumbers = ["13", "4", "18", "1", "20", "5",
                                    "12", "9", "14", "11", "8", "16",
                                    "7", "19", "3", "17", "2", "15",
                                    "10", "6"]
    
    var picker:SKSpriteNode!
    var selectedPicker:SKSpriteNode?
    var score:SKLabelNode!
    
    
    
    override func sceneDidLoad() {
        
        picker = SKSpriteNode(imageNamed: "dart")
        picker.name = "picker"
        picker.size = CGSize(width: 100, height: 100)
        picker.physicsBody = SKPhysicsBody(circleOfRadius: 1, center: CGPoint(x: -picker.size.width/2, y: picker.size.height/2))
        picker.physicsBody?.affectedByGravity = false
        picker.physicsBody?.contactTestBitMask = 1
        picker.physicsBody?.collisionBitMask = 0
        self.addChild(picker)
        
        score = SKLabelNode()
        score.text = "12"
        score.fontName = "NTWagner"
        
        score.position = CGPoint(x: self.frame.minX/2, y: self.frame.minY/2)
        self.addChild(score)
        
        self.physicsWorld.contactDelegate = self;
        
        for i in 1...20 {
            
            let centerAngle = 0 + (2 * CGFloat.pi / 20) * CGFloat(i)
            let gap:CGFloat = 0
    
            var multiplierColor, singleColor :UIColor
            var segmentsAtCurrentAngle:[SKShapeNode] = []
            
            if i%2 == 0 { multiplierColor =  green; singleColor = white}
            else { multiplierColor = red; singleColor = black }
            
            // MARK: NUMBER RING
            
            let numberRingPath = UIBezierPath.simonWedge(innerRadius: 300, outerRadius: 370, centerAngle: centerAngle, gap: 0)
            let numberRing = SKShapeNode(path: numberRingPath.cgPath, centered: false)
            numberRing.strokeColor = black
            numberRing.fillColor = black
            numberRing.name = "out"
            self.addChild(numberRing)
            
            let number = SKLabelNode()
            number.text = dartNumbers[i-1]
            number.fontName = "NTWagner"
            number.horizontalAlignmentMode = .center
            number.verticalAlignmentMode = .center
            number.position = CGPoint(x: numberRing.frame.midX, y: numberRing.frame.midY)
            numberRing.addChild(number)
            
            // MARK: DOUBLE SEGMENTS
            
            let triplePath = UIBezierPath.simonWedge(innerRadius: 260, outerRadius: 300, centerAngle: centerAngle, gap: gap)
            let triple = SKShapeNode(path: triplePath.cgPath, centered: false)
            triple.fillColor = multiplierColor
            triple.name = "double " + dartNumbers[i-1]
            segmentsAtCurrentAngle.append(triple)
            
            // MARK: SINGLE SEGMENT 1
            
            let upperSinglePath = UIBezierPath.simonWedge(innerRadius: 155, outerRadius: 260, centerAngle: centerAngle, gap: gap)
            let upperSingle = SKShapeNode(path: upperSinglePath.cgPath, centered: false)
            upperSingle.fillColor = singleColor
            upperSingle.name = dartNumbers[i-1]
            segmentsAtCurrentAngle.append(upperSingle)
            
            // MARK: DOUBLE SEGMENTS
            
            let doublePath = UIBezierPath.simonWedge(innerRadius: 115, outerRadius: 155, centerAngle: centerAngle, gap: gap)
            let double = SKShapeNode(path: doublePath.cgPath, centered: false)
            double.fillColor = multiplierColor
            double.name = "triple" + dartNumbers[i-1]
            segmentsAtCurrentAngle.append(double)

            // MARK: SINGLE SEGMENT 2
            
            let lowerSinglePath = UIBezierPath.simonWedge(innerRadius: 25, outerRadius: 115, centerAngle: centerAngle, gap: gap)
            let lowerSingle = SKShapeNode(path: lowerSinglePath.cgPath, centered: false)
            lowerSingle.fillColor = singleColor
            lowerSingle.name = dartNumbers[i-1]
            segmentsAtCurrentAngle.append(lowerSingle)
            
            
            // MARK: ADD AND SETUP PHYSICS BODY
            
            segmentsAtCurrentAngle.forEach{
                $0.physicsBody = SKPhysicsBody(polygonFrom: $0.path!)
                $0.physicsBody?.isDynamic = false
                $0.physicsBody?.contactTestBitMask = 1
                $0.physicsBody?.collisionBitMask = 0
                self.addChild($0)
            }
        }
        
        
       
        
    
        let bullseyePath = UIBezierPath()
        bullseyePath.addArc(withCenter: .zero, radius: 12.5, startAngle: 2*CGFloat.pi, endAngle: 4*CGFloat.pi, clockwise: true)
        bullseyePath.addArc(withCenter: .zero, radius: 24, startAngle: 4*CGFloat.pi, endAngle:  2*CGFloat.pi, clockwise: false)
        bullseyePath.close()
        
        let bullseye = SKShapeNode(path: bullseyePath.cgPath, centered: true)
        bullseye.fillColor = green
        bullseye.strokeColor = green
        bullseye.name = "bullseye"
        bullseye.physicsBody = SKPhysicsBody(polygonFrom: bullseyePath.reversing().cgPath)
        bullseye.physicsBody?.isDynamic = false
        bullseye.physicsBody?.contactTestBitMask = 1
        bullseye.physicsBody?.collisionBitMask = 0
        self.addChild(bullseye)
        
        let doubleBullseye = SKShapeNode(circleOfRadius: 12.5)
        doubleBullseye.fillColor = red
        doubleBullseye.name = "doubleBullseye"
        doubleBullseye.physicsBody = SKPhysicsBody(circleOfRadius: 12.5)
        doubleBullseye.physicsBody?.isDynamic = false
        doubleBullseye.physicsBody?.contactTestBitMask = 1
        doubleBullseye.physicsBody?.collisionBitMask = 0
        self.addChild(doubleBullseye)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            let touchedNodes = self.nodes(at: location)
            for n in touchedNodes.reversed()  {
                if n.name == "picker" {
                    selectedPicker = n as? SKSpriteNode
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let node = selectedPicker {
            let touchLocation = touch.location(in: self)
            node.position = touchLocation
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedPicker = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedPicker = nil
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        
        if (contact.bodyB.node?.name == "picker") {
            let allContactBodies = contact.bodyB.allContactedBodies()
            score.text = allContactBodies.first?.node?.name
        }
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let feedbackGenerator = UIImpactFeedbackGenerator()
        
        if (contact.bodyB.node?.name == "picker") {
            let allContactBodies = contact.bodyB.allContactedBodies()
            feedbackGenerator.prepare()
            score.text = allContactBodies.first?.node?.name
            feedbackGenerator.impactOccurred()
            //score.text = "end"
        }
    }
}

