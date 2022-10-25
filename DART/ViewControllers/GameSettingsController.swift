//  GameSettings.swift.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 18/10/21.
//

import Foundation
import UIKit

class GameSettingsController: UIViewController {

    @IBOutlet weak var playerNumber: UILabel!
    
    var gameData:GameData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerNumber.text = "1"
        // Do any additional setup after loading the view.
    }
    
    @IBAction func decrementPlayerNumber(_ sender: Any) {
        let count:Int = Int(playerNumber.text!)!
        if count > 1 { playerNumber.text = "\(count-1)" }
    }
    
    @IBAction func incrementPlayerNumber(_ sender: Any) {
        let count:Int = Int(playerNumber.text!)!
        if count < 6 { playerNumber.text = "\(count+1)" }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dartBoardScannerController" {
            let viewController = segue.destination as! DartBoardScannerController
            gameData.playerCount = Int(playerNumber.text!)!
            viewController.gameData = gameData
        }
    }
    
    
    @IBAction func unwindGameSettings( _ seg: UIStoryboardSegue) {}
    
    
    
}
