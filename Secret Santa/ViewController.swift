//
//  ViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
        
    var isHost: Bool!
    let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func menuAction(_ sender: Any) {
        
        self.present(menuAlert, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        activityIndicatorView.isHidden = true
        
        getRoomData()
        
        menuAlert.addAction(UIAlertAction(title: "Rooms", style: .default, handler: { (action) in
            print("Show Rooms in modal tableview")
        }))
        menuAlert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { (action) in
            self.logoutAction()
        }))
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
//        pairPeople()
    }
    
    func logoutAction() {
        let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            
            self.activityIndicatorView.isHidden = false

            let firebaseAuth = Auth.auth()
            
            do {
                try firebaseAuth.signOut()
                user = nil
                self.performSegue(withIdentifier: "logoutSegue", sender: self)
            } catch let signOutError as NSError {
                createAlert(view: self, title: "Error", message: signOutError.localizedDescription)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getRoomData() {
        
        // Get host
        // Get users
        // Get room name
        
    }
    
    
    // Assigns each person with their secret santa
    
    func pairPeople() {
        let count = userGroup.count
        var remaining = [Int]()
        
        for i in 0..<count {
            remaining.append(i)
        }
                
        for i in 0..<count {
            var num = Int(arc4random_uniform(UInt32(remaining.count)))
            
            while (userGroup[num] == userGroup[i]) {
                num = Int(arc4random_uniform(UInt32(count)))
            }
                        
            var index = 0
            
            for j in 0..<remaining.count {
                if num == j {
                    index = j
                }
            }
            
            let secret = remaining[index]
            let secretP = userGroup[secret]
            userGroup[i].assign(person: secretP)
            
            remaining.remove(at: index)

        }
                
//        Print who is paired with who
        
//        for person in group {
//            print(person.getName() + " is assigned to " + person.getSecretPerson()!.getName())
//        }
        
    }

}

