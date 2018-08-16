//
//  blankViewController.swift
//  Doom
//
//  Created by Michael Crimando on 8/16/18.
//

import UIKit

class blankViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Do any additional setup after loading the view.
//        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "space"))
//        let messageLabel = UILabel(frame: CGRect(x: self.view.frame.width/2, y: self.view.frame.height/2, width: self.view.frame.width, height: self.view.frame.height))
//        messageLabel.textAlignment = .center
//        messageLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//        messageLabel.font = UIFont(name: "GeezaPro-Bold", size: 70)
//        messageLabel.text = "Please return to the game"
//        self.view.addSubview(messageLabel)
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return UIInterfaceOrientationMask.portrait
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
