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
    var roomID: String!
    var roomHost: String!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func menuAction(_ sender: Any) {
        
        self.present(menuAlert, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getRoomData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
                                
        menuAlert.addAction(UIAlertAction(title: "Rooms", style: .default, handler: { (action) in
//            self.performSegue(withIdentifier: "roomDisplay", sender: self)
            let rd = RoomDisplayViewController()
            self.present(rd, animated: true, completion: nil)
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
        
        if roomID == "" {
//            performSegue(withIdentifier: "roomDisplay", sender: self)
            let rd = RoomDisplayViewController()
            self.present(rd, animated: true, completion: nil)
        }
        db.collection("rooms").document(roomID).getDocument { (querySnapshot, err) in
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
            } else {
                let data = querySnapshot!.data()!
                if data.count != 0 {
                    for key in data.keys {
                        if key != "locked" {
                            let usrUID = key
                            var usrList: Any!
                            if usrUID == "host" {
                                usrList = data[key] as! String
                            } else {
                                usrList = data[key] as! [String]
                            }
                            
                            dataGroup.append([usrUID:usrList!])
                        }
                    }
                    for usr in dataGroup {
                        var host = false
                        var usrUID = usr.keys.first!
                        if usrUID == "host" {
                            host = true
                            usrUID = usr[usrUID] as! String
                        }
                        db.collection("users").document(usrUID).getDocument { (document, err) in
                            
                            if let err = err {
                                print(err)
                            } else  if let _ = document, document!.exists {
                                let rawdata = document!.data()!
                                let data = rawdata["userdata"] as! [String:Any]
                                let personName = (data["first"] as! String) + " " + (data["last"] as! String)

                                if host {
                                    self.roomHost = personName
                                } else {
                                    let personWishlist = usr[usrUID] as! [String]
                                    if usrUID == user.uid {
                                        wishlist = personWishlist
                                    } else {
                                        let person = Person(name: personName)
                                        person.setWishList(list: personWishlist)
                                        userGroup.append(person)
                                    }
                                }

                            } else {
                                print(usrUID+" does not exist")
                            }
                        }
                        
                    }
                    
                    self.navigationItem.title = self.roomID
                    self.activityIndicatorView.isHidden = true
                    defaults.set(self.roomID, forKey: "currentRoom")
                }
            }
        }
        

        
        // Get host
        // Get users
        // Get room name
        
//        pairPeople()
        
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
        
        for person in userGroup {
            print(person.getName() + " is assigned to " + person.getSecretPerson()!.getName())
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToWish" {
            let controller = segue.destination as! WishlistViewController
            controller.roomID = self.roomID
        }
    }

}

