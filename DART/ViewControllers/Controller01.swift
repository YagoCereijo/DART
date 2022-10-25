//
//  501Controller.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 19/10/21.
//

import Foundation
import UIKit

class Controller01: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var gameData: GameData!
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var round: UILabel!
    @IBOutlet weak var ppr: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.delegate = self
        table.dataSource = self
        gameData.playersScore = Array(repeating: gameData.initialScore, count: gameData.playerCount)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return table.frame.height / (CGFloat(gameData.playerCount) + 1.55)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return gameData.playerCount
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell")!
        cell.textLabel!.text = "Player \(indexPath.section + 1)"
        cell.detailTextLabel!.text = "\(gameData.playersScore[indexPath.section])"
        cell.layer.cornerRadius = 10
        if gameData.currentPlayer == indexPath.section { cell.layer.borderColor = UIColor(named: "green")?.cgColor; cell.layer.borderWidth = 5}
        else { cell.layer.borderWidth = 0 }
        
        return cell
    }
    
    
   
    
    
//  MARK: SEGUES
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScannerSegue" {
            let controllerView = segue.destination as! ScannerController
            controllerView.gameData = gameData
        }
    }
    
    
    @IBAction func unwindToController01WithResults( _ seg: UIStoryboardSegue) {
        
        var controller = seg.source as! ScannerController
        let cell = table.cellForRow(at: IndexPath(row: 0, section: gameData.currentPlayer))!
        let currentScore = Int(cell.detailTextLabel!.text!)!
        
        let allResults = controller.scoreResults.map{$0.score}
        
        let points = getPoints(allResults)
        
        if(gameData.playersScore[gameData.currentPlayer] - points == 0){
            
            displayMessage(text: "Winner", color: UIColor(named: "green")!, action: 1)
            
        }else if(gameData.playersScore[gameData.currentPlayer] - points > 0){
            
            gameData.playersScore[gameData.currentPlayer] = currentScore - points
            
            if  gameData.currentPlayer + 1 ==  gameData.playerCount {
                gameData.currentPlayer = 0;
                round.text = "\(Int(round.text!)! + 1)"
                ppr.text = "\(Int( Float(gameData.initialScore -  gameData.playersScore[ gameData.currentPlayer]) / (Float(round.text!)! - 1)))"
            } else {
                gameData.currentPlayer += 1
                ppr.text = "\(Int( Float(gameData.initialScore -  gameData.playersScore[ gameData.currentPlayer]) / (Float(round.text!)!)))"
            }
            
            table.reloadData()
            
        }else{
            
            displayMessage(text: "BUSTED", color: UIColor(named: "red")!, action: 2)
            
            if  gameData.currentPlayer + 1 ==  gameData.playerCount {
                gameData.currentPlayer = 0;
                round.text = "\(Int(round.text!)! + 1)"
                ppr.text = "\(Int( Float(gameData.initialScore -  gameData.playersScore[ gameData.currentPlayer]) / (Float(round.text!)! - 1)))"
            } else {
                gameData.currentPlayer += 1
                ppr.text = "\(Int( Float(gameData.initialScore -  gameData.playersScore[ gameData.currentPlayer]) / (Float(round.text!)!)))"
            }
        }
        
        if Int(round.text!) == 21 {
            
            let winner = gameData.playersScore.firstIndex(where: {$0 == gameData.playersScore.max()!})! + 1
            displayMessage(text: "PLAYER \(winner) WINS", color: UIColor(named: "green")!, action: 1)

        }
    }
    
    func displayMessage(text: String, color: UIColor, action: Int){
        let messageButton = UIButton()
        messageButton.setTitle(text, for: .normal)
        messageButton.titleLabel?.numberOfLines = 0;
        messageButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        messageButton.setTitleColor(color, for: .normal)
        messageButton.titleLabel!.font = UIFont(name: "NTWagner", size: 60)
        messageButton.titleLabel?.textAlignment = .center
        messageButton.tag = action
        messageButton.addTarget(self, action:#selector(buttonTapped), for: .touchDown)
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(messageButton)
        messageButton.insertSubview(blur, at: 0)
        
        
        NSLayoutConstraint.activate([
            messageButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            messageButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            messageButton.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            messageButton.heightAnchor.constraint(equalTo: self.view.heightAnchor),
            blur.centerXAnchor.constraint(equalTo: messageButton.centerXAnchor),
            blur.centerYAnchor.constraint(equalTo: messageButton.centerYAnchor),
            blur.widthAnchor.constraint(equalTo: messageButton.widthAnchor),
            blur.heightAnchor.constraint(equalTo: messageButton.heightAnchor)
        ])
    }
    
    @IBAction func unwindToController01( _ seg: UIStoryboardSegue) {}
    
    func getPoints(_ results:[String])->Int{
        var score = 0
        for result in results {
            switch result{
            case "⦾": score += 25
            case "⦿": score += 50
            case "x": break;
            default:
                let components = result.components(separatedBy: "-")
                if components.count == 1 { score += Int(result)! }
                else if components.count == 2 {
                    switch components[0]{
                    case "T": score += Int(components[1])! * 3
                    case "D": score += Int(components[1])! * 2
                    default: break
                    }
                }
            }
        }
        
        return score
    }
    
    @objc func buttonTapped(sender : UIButton) {
        switch sender.tag {
        case 1:
            performSegue(withIdentifier: "unwindHome", sender: self)
        case 2:
            UIView.animate(withDuration: 1, animations: {
                sender.frame.origin.x += sender.frame.width
                sender.backgroundColor = UIColor(named: "black")?.withAlphaComponent(0)
            }, completion: { _ in
                sender.removeFromSuperview()
            })
        default: print("Something went wrong")
        }
    }
}
