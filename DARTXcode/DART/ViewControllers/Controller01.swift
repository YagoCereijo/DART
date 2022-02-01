//
//  501Controller.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 19/10/21.
//

import Foundation
import UIKit

class Controller01: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var numberOfPlayers:Int!
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.delegate = self
        table.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return table.frame.height / (CGFloat(numberOfPlayers) + 1.55)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfPlayers
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell")!
        cell.textLabel!.text = "Player \(indexPath.section + 1)"
        cell.detailTextLabel!.text = "301"
        cell.layer.cornerRadius = 10
        
        return cell
    }
    
}
