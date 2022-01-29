//
//  ViewController.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 18/10/21.
//

import iCarousel
import UIKit

class ViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    
    let customForeground = UIColor(cgColor: CGColor(red: 231/255, green: 210/255, blue: 186/255, alpha: 1))
    let darkBackground = UIColor(cgColor: CGColor(red: 45/255, green: 41/255, blue: 38/255, alpha: 1))
    let lightBackground = UIColor(cgColor: CGColor(red: 237/255, green: 231/255, blue: 225/255, alpha: 1))
    let customGreen = UIColor(cgColor: CGColor(red: 0, green: 148/255, blue: 115/255, alpha: 1))
    let customRed = UIColor(cgColor: CGColor(red: 191/255, green: 25/255, blue: 50/255, alpha: 1))
    

    let games = ["301", "501", "701", "Cricket", "Golf", "Loco", "301", "501", "701", "Cricket", "Golf", "Loco"]
    
    let carousel = iCarousel()
    let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = lightBackground
        
        carousel.type = .coverFlow
        carousel.dataSource = self
        carousel.delegate = self
        carousel.backgroundColor = lightBackground
        carousel.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = "\tDart"
        label.font = UIFont(name: "NTWagner", size: 30)
        label.textColor = customForeground
        label.backgroundColor = darkBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(carousel)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1),
            label.widthAnchor.constraint(equalTo: view.widthAnchor),
            label.bottomAnchor.constraint(equalTo: carousel.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carousel.widthAnchor.constraint(equalTo: view.widthAnchor),
            carousel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carousel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        let card = UIView()
        let label = UILabel()
        let button = UIButton(type: .infoDark)
        
        card.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width*0.6, height: self.view.frame.size.height*0.6)
        
        card.layer.cornerRadius = 25
        card.layer.borderWidth = 5
        if index%2 == 0 { card.layer.borderColor = customRed.cgColor; label.backgroundColor = customRed}
        else { card.layer.borderColor = customGreen.cgColor; label.backgroundColor = customGreen}
        
        label.text = games[index]
        label.font = UIFont(name: "NTWagner", size: 40)
        label.textColor = customForeground
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        button.tintColor = customForeground
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showGameInfo), for: .touchDown)
        
        card.addSubview(button)
        card.addSubview(label)
        
        card.backgroundColor = darkBackground
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.topAnchor, constant: 5),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -5),
            button.heightAnchor.constraint(equalTo: card.heightAnchor, multiplier: 0.12),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            label.widthAnchor.constraint(equalTo: card.widthAnchor),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        return card
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        games.count
    }
    
    @objc func showGameInfo(sender: UIButton){
        
        let card = sender.superview!
        
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]

        UIView.transition(with: card, duration: 1.0, options: transitionOptions, animations: nil)

        /*
        UIView.transition(with: secondView, duration: 1.0, options: transitionOptions, animations: {
            nil
        })*/
    }
}

