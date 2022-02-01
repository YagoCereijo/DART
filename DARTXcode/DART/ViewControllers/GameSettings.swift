//  GameSettings.swift.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 18/10/21.
//

import Foundation
import UIKit

class GameSettings: UIViewController {

    @IBOutlet weak var playerNumber: UILabel!
    
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
    
    @IBAction func unwind( _ seg: UIStoryboardSegue) {
        self.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "01" {
            let view = segue.destination as! Controller01
            view.numberOfPlayers = Int(playerNumber.text!)!
        }
    }
    
    
    
}
