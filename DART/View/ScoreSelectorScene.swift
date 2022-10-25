//
//  DartSelectorScene.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 3/2/22.
//

import SpriteKit
import GameplayKit
import Vision

typealias Radians = CGFloat

protocol ScoreSelectorSceneDelegate: AnyObject {
    func dataChanged(atIndex:Int, newScoreResult: (String, CGRect))
    func dataAdded(newScoreResult: (String, CGRect))
}

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

class ScoreSelectorScene: SKScene, SKPhysicsContactDelegate{
    
    
    let red = UIColor(named: "red") ?? .red
    let green = UIColor(named: "green") ?? .green
    let white = UIColor(named: "white") ?? .white
    let black = UIColor(named: "black") ?? .black
    
    let dartNumbers = ["13", "4", "18", "1", "20", "5",
                                    "12", "9", "14", "11", "8", "16",
                                    "7", "19", "3", "17", "2", "15",
                                    "10", "6"]
    
    weak var scoreSelectorDelegate: ScoreSelectorSceneDelegate?
    
    var picker:SKSpriteNode!
    var selectedPicker:SKSpriteNode?
    var score:SKLabelNode!
    var maxRadius:CGFloat!
    var darts:[SKSpriteNode] = []
    var results:[String]!
    
    override init(){
        super.init()
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        maxRadius = self.frame.width*0.8/2
        self.backgroundColor = .clear
        self.physicsWorld.contactDelegate = self;
        
        for i in 1...20 {
            
            let centerAngle = (2 * CGFloat.pi / 20) * CGFloat(i)
            let gap:CGFloat = 0
    
            var multiplierColor, singleColor :UIColor
            var segmentsAtCurrentAngle:[SKShapeNode] = []
            
            if i%2 == 0 { multiplierColor =  green; singleColor = white}
            else { multiplierColor = red; singleColor = black }
            
            
            
            // MARK: NUMBER RING
            
            let numberRingPath = UIBezierPath.simonWedge(innerRadius: maxRadius * 0.85, outerRadius: maxRadius, centerAngle: centerAngle, gap: 0)
            let numberRing = SKShapeNode(path: numberRingPath.cgPath, centered: false)
            numberRing.strokeColor = black
            numberRing.fillColor = black
            numberRing.name = "x"
            segmentsAtCurrentAngle.append(numberRing)
            
            let number = SKLabelNode()
            number.text = dartNumbers[i-1]
            number.fontName = "NTWagner"
            number.fontSize = 15
            number.horizontalAlignmentMode = .center
            number.verticalAlignmentMode = .center
            number.position = CGPoint(x: numberRing.frame.midX, y: numberRing.frame.midY)
            numberRing.addChild(number)
            
            // MARK: DOUBLE SEGMENTS
            
            let doublePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.75, outerRadius: maxRadius*0.85, centerAngle: centerAngle, gap: gap)
            let double = SKShapeNode(path: doublePath.cgPath, centered: false)
            double.fillColor = multiplierColor
            double.name = "D-" + dartNumbers[i-1]
            segmentsAtCurrentAngle.append(double)
            
            // MARK: SINGLE SEGMENT 1
            
            let upperSinglePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.525, outerRadius: maxRadius*0.75, centerAngle: centerAngle, gap: gap)
            let upperSingle = SKShapeNode(path: upperSinglePath.cgPath, centered: false)
            upperSingle.fillColor = singleColor
            upperSingle.name = dartNumbers[i-1]
            segmentsAtCurrentAngle.append(upperSingle)
            
            // MARK: TRIPLE SEGMENTS
            
            let triplePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.425, outerRadius: maxRadius*0.525, centerAngle: centerAngle, gap: gap)
            let triple = SKShapeNode(path: triplePath.cgPath, centered: false)
            triple.fillColor = multiplierColor
            triple.name = "T-" + dartNumbers[i-1]
            segmentsAtCurrentAngle.append(triple)

            // MARK: SINGLE SEGMENT 2
            
            let lowerSinglePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.1, outerRadius: maxRadius*0.425, centerAngle: centerAngle, gap: gap)
            let lowerSingle = SKShapeNode(path: lowerSinglePath.cgPath, centered: false)
            lowerSingle.fillColor = singleColor
            lowerSingle.name = dartNumbers[i-1]
            segmentsAtCurrentAngle.append(lowerSingle)
            
            
            // MARK: ADD AND SETUP PHYSICS BODY
            
            segmentsAtCurrentAngle.forEach{
                $0.physicsBody = SKPhysicsBody(polygonFrom: $0.path!)
                $0.physicsBody?.isDynamic = false
                $0.physicsBody?.categoryBitMask = 1
                self.addChild($0)
            }
             
        }
    
        let bullseyePath = UIBezierPath()
        bullseyePath.addArc(withCenter: .zero, radius: maxRadius*0.1, startAngle: 2*CGFloat.pi, endAngle: 4*CGFloat.pi, clockwise: true)
        bullseyePath.addArc(withCenter: .zero, radius: maxRadius*0.05, startAngle: 4*CGFloat.pi, endAngle:  2*CGFloat.pi, clockwise: false)
        bullseyePath.close()
        
        let bullseye = SKShapeNode(path: bullseyePath.cgPath, centered: false)
        bullseye.fillColor = green
        bullseye.strokeColor = green
        bullseye.name = "⦾"
        bullseye.physicsBody = SKPhysicsBody(polygonFrom: bullseyePath.cgPath)
        bullseye.physicsBody?.isDynamic = false
        bullseye.physicsBody?.categoryBitMask = 1
        self.addChild(bullseye)
        
        let doubleBullseye = SKShapeNode(circleOfRadius: maxRadius*0.05)
        doubleBullseye.fillColor = red
        doubleBullseye.name = "⦿"
        doubleBullseye.physicsBody = SKPhysicsBody(circleOfRadius: maxRadius*0.05)
        doubleBullseye.physicsBody?.isDynamic = false
        doubleBullseye.physicsBody?.categoryBitMask = 1
        self.addChild(doubleBullseye)
        
        let dartBoardBorder = SKShapeNode(circleOfRadius: maxRadius)
        dartBoardBorder.fillColor = .clear
        dartBoardBorder.strokeColor = .white
        self.addChild(dartBoardBorder)
        
        
        var count = 21
        self.results?.forEach{
            let dart = SKSpriteNode(imageNamed: "dart")
            dart.name = "\(count)"
            count += 1
            dart.anchorPoint = CGPoint(x: 1, y: 0)
            dart.size = CGSize(width: frame.width/7.5, height: frame.height/7.5)
            
            dart.physicsBody = SKPhysicsBody(circleOfRadius: 1, center: CGPoint(x: dart.frame.minX, y: dart.frame.maxY))
            dart.physicsBody?.affectedByGravity = false
            dart.physicsBody?.contactTestBitMask = 0
            dart.physicsBody?.collisionBitMask = 0
            
            let spawnNode = self.childNode(withName: $0)!
            dart.position = CGPoint(x: spawnNode.frame.midX + dart.frame.width, y: spawnNode.frame.midY - dart.frame.height)
            self.addChild(dart)
            darts.append(dart)
            
            
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNodes = self.nodes(at: location)
            for n in touchedNodes.reversed()  {
                if ["21", "22", "23"].contains(n.name) {
                    selectedPicker = n as? SKSpriteNode
                    selectedPicker?.physicsBody?.contactTestBitMask = 1
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let node = selectedPicker {
            let touchLocation = touch.location(in: self)
            if sqrt(pow(touchLocation.x - node.frame.width ,2) + pow(touchLocation.y + node.frame.height,2)) < maxRadius {
                node.position = touchLocation
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedPicker = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedPicker = nil
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        
        let allContactBodies = contact.bodyB.allContactedBodies()
        let hitted = allContactBodies[allContactBodies.firstIndex(where: {!["21", "22", "23"].contains($0.node?.name)})!].node
        if let dart = contact.bodyB.node {
            let dartId = dart.name!
            if ["21", "22", "23"].contains(dartId) {
                let newScore = hitted?.name ?? "x"
                let index = Int(dartId)!-21
                results[index] = newScore
                scoreSelectorDelegate?.dataChanged(atIndex: index,
                                                   newScoreResult: (newScore, CGRect(x: ((dart.frame.minX + maxRadius) / (maxRadius*2)) - 0.05,
                                                                                     y: ((dart.frame.maxY + maxRadius) / (maxRadius*2)) - 0.05,
                                                                                     width: 0.1,
                                                                                     height: 0.1)))

                
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let allContactBodies = contact.bodyB.allContactedBodies()
        let hitted = allContactBodies[allContactBodies.firstIndex(where: {!["21", "22", "23"].contains($0.node?.name)})!].node
        if let dart = contact.bodyB.node{
            let dartId = dart.name!
            let feedbackGenerator = UIImpactFeedbackGenerator()
            if ["21", "22", "23"].contains(dartId) {
                let newScore = hitted?.name ?? "x"
                let index = Int(dartId)!-21
                results[index] = newScore
                feedbackGenerator.prepare()
                feedbackGenerator.impactOccurred()
                scoreSelectorDelegate?.dataChanged(atIndex: index,
                                                   newScoreResult: (newScore, CGRect(x: ((dart.frame.minX + maxRadius) / (maxRadius*2)) - 0.05,
                                                                                     y: ((dart.frame.maxY + maxRadius) / (maxRadius*2)) - 0.05,
                                                                                     width: 0.1,
                                                                                     height: 0.1)))
            }
        }
    }
    
    
    @objc func addDart(){
        if results.count < 3 {
            results.append("20")
            let dart = SKSpriteNode(imageNamed: "dart")
            dart.name = "\(20+results.count)"
            dart.anchorPoint = CGPoint(x: 1, y: 0)
            dart.size = CGSize(width: 50, height: 50)
            dart.physicsBody = SKPhysicsBody(circleOfRadius: 1, center: CGPoint(x: dart.frame.minX, y: dart.frame.maxY))
            dart.physicsBody?.affectedByGravity = false
            dart.physicsBody?.contactTestBitMask = 1
            dart.physicsBody?.collisionBitMask = 0
            darts.append(dart)
            let spawnNode = self.childNode(withName: "20")!
            dart.position = CGPoint(x: spawnNode.frame.midX + dart.frame.width, y: spawnNode.frame.midY - dart.frame.height)
            self.addChild(dart)
            scoreSelectorDelegate?.dataAdded(newScoreResult: ("20", CGRect(x: ((dart.frame.minX+self.frame.width/2) / self.frame.width) - 0.05,
                                                                           y: ((dart.frame.maxY+self.frame.height/2) / self.frame.height) - 0.05,
                                                                           width: 0.1,
                                                                           height: 0.1)))
                                             
        }
    }
}


