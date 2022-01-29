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
    
    @IBAction func changePlayerNumber(_ sender: UIStepper) {
        let count:Int = Int(sender.value)
        playerNumber.text = "\(count)"
    }
    
    
}
