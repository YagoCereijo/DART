//
//  GameData.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 9/8/22.
//

import Foundation
import UIKit

struct GameData {
    
    var game:String
    var playerCount:Int!
    var refImage:CIImage!
    var targetImage:CIImage!
    var currentPlayer = 0
    var playersScore:[Int]!
    lazy var initialScore = {return Int(game)!}()
    
    init(game: String){
        self.game = game
    }
}
