//
//  ViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var userName: UITextView!
    @IBOutlet weak var userWishList: UITextView!
    @IBOutlet weak var submitButtom: UIButton!
    
    var user = Person
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    let p1 = Person(name:"Au")
    let p2 = Person(name:"Ma")
    let p3 = Person(name:"Gu")
    let p4 = Person(name:"Su")
    let p5 = Person(name:"Ta")
    

}

