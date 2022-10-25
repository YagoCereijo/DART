//
//  ViewController.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 18/10/21.
//

import iCarousel
import UIKit

class ViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
        

    private let games = ["301", "501", "701"]
    private let carousel = iCarousel()
    private var selectedGame:Int!
    
    @IBOutlet weak var carouselContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "white")
        
        carousel.type = .coverFlow
        carousel.dataSource = self
        carousel.delegate = self
        carousel.backgroundColor = UIColor.clear
        carousel.translatesAutoresizingMaskIntoConstraints = false
        
        carouselContainer.addSubview(carousel)
        
        NSLayoutConstraint.activate([
            carousel.heightAnchor.constraint(equalTo: carouselContainer.heightAnchor),
            carousel.widthAnchor.constraint(equalTo: carouselContainer.widthAnchor),
            carousel.centerXAnchor.constraint(equalTo: carouselContainer.centerXAnchor),
            carousel.centerYAnchor.constraint(equalTo: carouselContainer.centerYAnchor)
        ])
    }
    
    // MARK: CAROUSEL SETUP
    
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let card = UIView()
        let label = UILabel()
        
        card.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width*0.6, height: self.view.frame.size.height*0.6)
        card.layer.cornerRadius = 25
        card.layer.borderWidth = 5
        
        if index%2 == 0 { card.layer.borderColor = UIColor(named: "red")?.cgColor; label.backgroundColor = UIColor(named: "red")}
        else { card.layer.borderColor = UIColor(named: "green")?.cgColor; label.backgroundColor = UIColor(named: "green")}
        
        label.text = games[index]
        label.font = UIFont(name: "NTWagner", size: 40)
        label.textColor = UIColor(named: "white")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(label)
        
        card.backgroundColor = UIColor(named: "black")
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            label.widthAnchor.constraint(equalTo: card.widthAnchor),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        return card
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        games.count
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        selectedGame = index
        performSegue(withIdentifier: "GameSettingsSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GameSettingsSegue" {
            let viewController = segue.destination as! GameSettingsController
            viewController.gameData = GameData(game: games[selectedGame])
        }
    }
    
    
   
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func unwindHome( _ seg: UIStoryboardSegue) {}

}

