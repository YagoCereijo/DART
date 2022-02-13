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

class DartSelectorScene: SKScene, SKPhysicsContactDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    
    
    
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
    var maxRadius:CGFloat!
    var darts:[SKSpriteNode] = []
    var results:[String]!
    var DartCollection:UICollectionView
    
    public init(size: CGSize, results: [String], dartCollection: UICollectionView){
        if results.count > 3 {self.results = [String](results[0..<3])}
        else {self.results = results}
        print(results)
        self.DartCollection = dartCollection
        super.init(size: size)
        self.DartCollection.delegate = self
        self.DartCollection.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sceneDidLoad() {
        
        maxRadius = self.size.width/2
        
        self.physicsWorld.contactDelegate = self;
        
        for i in 1...20 {
            
            let centerAngle = 0 + (2 * CGFloat.pi / 20) * CGFloat(i)
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
            numberRing.name = "out"
            self.addChild(numberRing)
            
            let number = SKLabelNode()
            number.text = dartNumbers[i-1]
            number.fontName = "NTWagner"
            number.fontSize = 15
            number.horizontalAlignmentMode = .center
            number.verticalAlignmentMode = .center
            number.position = CGPoint(x: numberRing.frame.midX, y: numberRing.frame.midY)
            numberRing.addChild(number)
            
            // MARK: DOUBLE SEGMENTS
            
            let triplePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.75, outerRadius: maxRadius*0.85, centerAngle: centerAngle, gap: gap)
            let triple = SKShapeNode(path: triplePath.cgPath, centered: false)
            triple.fillColor = multiplierColor
            triple.name = dartNumbers[i-1] + " D"
            segmentsAtCurrentAngle.append(triple)
            
            // MARK: SINGLE SEGMENT 1
            
            let upperSinglePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.525, outerRadius: maxRadius*0.75, centerAngle: centerAngle, gap: gap)
            let upperSingle = SKShapeNode(path: upperSinglePath.cgPath, centered: false)
            upperSingle.fillColor = singleColor
            upperSingle.name = dartNumbers[i-1]
            segmentsAtCurrentAngle.append(upperSingle)
            
            // MARK: TRIPLE SEGMENTS
            
            let doublePath = UIBezierPath.simonWedge(innerRadius: maxRadius*0.425, outerRadius: maxRadius*0.525, centerAngle: centerAngle, gap: gap)
            let double = SKShapeNode(path: doublePath.cgPath, centered: false)
            double.fillColor = multiplierColor
            double.name = dartNumbers[i-1] + " T"
            segmentsAtCurrentAngle.append(double)

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
                $0.physicsBody?.contactTestBitMask = 1
                $0.physicsBody?.collisionBitMask = 0
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
        bullseye.name = "bullseye"
        bullseye.physicsBody = SKPhysicsBody(polygonFrom: bullseyePath.cgPath)
        bullseye.physicsBody?.isDynamic = false
        bullseye.physicsBody?.contactTestBitMask = 1
        bullseye.physicsBody?.collisionBitMask = 0
        self.addChild(bullseye)
        
        let doubleBullseye = SKShapeNode(circleOfRadius: maxRadius*0.05)
        doubleBullseye.fillColor = red
        doubleBullseye.name = "doubleBullseye"
        doubleBullseye.physicsBody = SKPhysicsBody(circleOfRadius: maxRadius*0.05)
        doubleBullseye.physicsBody?.isDynamic = false
        doubleBullseye.physicsBody?.contactTestBitMask = 1
        doubleBullseye.physicsBody?.collisionBitMask = 0
        self.addChild(doubleBullseye)
        
        var count = 21
        self.results?.forEach{
            let dart = SKSpriteNode(imageNamed: "dart")
            dart.name = "\(count)"
            count += 1
            dart.anchorPoint = CGPoint(x: 1, y: 0)
            dart.size = CGSize(width: size.width/7.5, height: size.height/7.5)
            dart.physicsBody = SKPhysicsBody(circleOfRadius: 1, center: CGPoint(x: dart.frame.minX, y: dart.frame.maxY))
            dart.physicsBody?.affectedByGravity = false
            dart.physicsBody?.contactTestBitMask = 1
            dart.physicsBody?.collisionBitMask = 0
            darts.append(dart)
            let spawnNode = self.childNode(withName: $0)!
            dart.position = CGPoint(x: spawnNode.frame.midX + dart.frame.width, y: spawnNode.frame.midY - dart.frame.height)
            self.addChild(dart)
        }
        
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            let touchedNodes = self.nodes(at: location)
            for n in touchedNodes.reversed()  {
                if ["21", "22", "23"].contains(n.name) {
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
        let name = contact.bodyB.node?.name ?? "out"
        if ["21", "22", "23"].contains(name) {
            let allContactBodies = contact.bodyB.allContactedBodies()
            results[Int(name)!-21] = allContactBodies.first?.node?.name ?? "out"
            DartCollection.reloadData()
        }
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let name = contact.bodyB.node?.name ?? "out"
        let feedbackGenerator = UIImpactFeedbackGenerator()
        
        if ["21", "22", "23"].contains(name) {
            let allContactBodies = contact.bodyB.allContactedBodies()
            results[Int(name)!-21] = allContactBodies.first?.node?.name ?? "out"
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
            DartCollection.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if results.count < 3 { return results.count+1 }
        else { return results.count }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < results.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DartCell", for: indexPath) as! DartCell
            cell.result.text = results[indexPath.row]
            return cell
        } else if indexPath.row <= results.count{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddDartCell", for: indexPath) as! AddDartCell
            cell.button.addTarget(self, action: #selector(addDart), for: .touchDown)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    @objc func addDart(){
        results.append("20 T")
        DartCollection.reloadData()
        let dart = SKSpriteNode(imageNamed: "dart")
        dart.name = "\(20+results.count)"
        dart.anchorPoint = CGPoint(x: 1, y: 0)
        dart.size = CGSize(width: size.width/7.5, height: size.height/7.5)
        dart.physicsBody = SKPhysicsBody(circleOfRadius: 1, center: CGPoint(x: dart.frame.minX, y: dart.frame.maxY))
        dart.physicsBody?.affectedByGravity = false
        dart.physicsBody?.contactTestBitMask = 1
        dart.physicsBody?.collisionBitMask = 0
        darts.append(dart)
        let spawnNode = self.childNode(withName: "20 T")!
        dart.position = CGPoint(x: spawnNode.frame.midX + dart.frame.width, y: spawnNode.frame.midY - dart.frame.height)
        self.addChild(dart)
        
    }
}

