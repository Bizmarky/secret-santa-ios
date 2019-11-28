//
//  ViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    // list of people in the group
    var group = [Person]()
    
    let p1 = Person(name:"Marcus")
    let p2 = Person(name:"Augustine")
    let p3 = Person(name:"Bobby")
    let p4 = Person(name:"Joe")
    let p5 = Person(name:"Maison")
    let p6 = Person(name:"Sophia")
    let p7 = Person(name:"Karen")
    let p8 = Person(name:"Pam")
    let p9 = Person(name:"Michael")
    let p10 = Person(name:"Zack")
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
                
        wishlist = ["toys", "games", "candy", "electronics", "car"]
        
        group.append(p1)
        group.append(p2)
        group.append(p3)
        group.append(p4)
        group.append(p5)
        group.append(p6)
        group.append(p7)
        group.append(p8)
        group.append(p9)
        group.append(p10)

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
                        
            var index = 0
            
            for j in 0..<remaining.count {
                if num == j {
                    index = j
                }
            }
            
            let secret = remaining[index]
            let secretP = group[secret]
            group[i].assign(person: secretP)
            
            remaining.remove(at: index)

        }
                
//        Print who is paired with who
        
//        for person in group {
//            print(person.getName() + " is assigned to " + person.getSecretPerson()!.getName())
//        }
        
    }

}

