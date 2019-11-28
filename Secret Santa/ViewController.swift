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
    
//    var user = Person
    
    // list of people in the group
    var group = [Person]()
    
    let p1 = Person(name:"Au")
    let p2 = Person(name:"Ma")
    let p3 = Person(name:"Gu")
    let p4 = Person(name:"Su")
    let p5 = Person(name:"Ta")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        group.append(p1)
        group.append(p2)
        group.append(p3)
        group.append(p4)
        group.append(p5)

        pairPeople()
    }
    
    
    // Assigns each person with their secret santa
    
    func pairPeople() {
        let count = group.count
        var remaining = [Int]()
        
        for i in 0..<count {
            remaining.append(i)
        }
                
        for i in 0..<count {
            var num = Int(arc4random_uniform(UInt32(remaining.count)))
            
            while (group[num] == group[i]) {
                num = Int(arc4random_uniform(UInt32(count)))
            }
                                    
            group[i].assign(person: group[remaining[num]])
            
            remaining.remove(at: num)

        }
                        
        for person in group {
            print(person.getName() + " is assigned to " + person.getSecretPerson().getName())
        }
        
    }

}

