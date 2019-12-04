//
//  SetupViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class SetupViewController: UIViewController, UITextFieldDelegate {
    
    var host: Bool!
    var join: Bool!
    var titleText: UILabel!
    var roomID: String!
    var fromHome = false
    
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    
    @IBOutlet weak var groupIDField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBAction func logoutAction(_ sender: Any) {
        if fromHome {
            dismiss(animated: true, completion: nil)
        } else {
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
    }
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        groupIDField.delegate = self
        
        setLogoutButton()
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.layer.cornerRadius = submitButton.frame.height/4
        
        titleText = UILabel(frame: CGRect(origin: self.view.center, size: CGSize(width: self.view.frame.width, height: 18)))
        titleText.translatesAutoresizingMaskIntoConstraints = false
        
        titleText.font = .systemFont(ofSize: 16, weight: .semibold)
        self.navigationItem.titleView = titleText
        self.navigationItem.setHidesBackButton(true, animated: true)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        userTypeAction(self)
                
        userGroup = []
        dataGroup = []
        
        hostRoomList = []
        joinRoomList = []
        
        hideAll()
        checkRoom()
                
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        buttonAction(self)
        return true
    }
    
    func setLogoutButton() {
        if fromHome {
            logoutButton.setTitle("Cancel", for: .normal)
        }
    }
    
    func hideAll() {
        logoutButton.alpha = 0
        userTypeControl.alpha = 0
        groupIDField.alpha = 0
        submitButton.alpha = 0
        titleText.alpha = 0
    }
    
    func showAll() {
        UIView.animate(withDuration: 0.2) {
            self.logoutButton.alpha = 1
            self.userTypeControl.alpha = 1
            self.groupIDField.alpha = 1
            self.submitButton.alpha = 1
            self.titleText.alpha = 1
        }
    }
    
    func checkRoom() {
        db.collection("users").document(user.uid).getDocument { (document, err) in
            if let err = err {
                print(err)
                self.showAll()
                self.activityIndicatorView.isHidden = true
            } else {
                let data = document?.data()?.values.first as! [String:Any]
                
                let dataRooms = data["rooms"] as! [String]
                let hostRooms = data["host"] as! [String]
                
                if userData == nil {
                    userData = [:]
                }
                
                userData["first"] = (data["first"] as! String)
                userData["last"] = (data["last"] as! String)
                userData["email"] = (data["email"] as! String)
                
                if dataRooms.isEmpty && hostRooms.isEmpty {
                    self.showAll()
                    self.activityIndicatorView.isHidden = true
                } else {
                    for room in hostRooms {
                        hostRoomList.append(room)
                    }
                    for room in dataRooms {
                        if !hostRoomList.contains(room) {
                            joinRoomList.append(room)
                        }
                    }
                    if !self.fromHome {
                        self.prepareRoom()
                    } else {
                        self.showAll()
                        self.activityIndicatorView.isHidden = true
                    }
                }
            }
        }
    }
    
    func prepareRoom() {
        self.roomID = ""
        
        if defaults.object(forKey: "currentRoom") != nil {
            self.roomID = defaults.string(forKey: "currentRoom")
        } else if !hostRoomList.isEmpty {
            if hostRoomList.count == 1 {
                self.roomID = hostRoomList[0]
            }
        } else if !joinRoomList.isEmpty {
            if joinRoomList.count == 1 {
                self.roomID = joinRoomList[0]
            }
        }
        
        self.performSegue(withIdentifier: "mainToHome", sender: self)
    }
    
    @IBAction func userTypeAction(_ sender: Any) {
        if self.userTypeControl.selectedSegmentIndex == 0 {
            self.setupHost()
        } else if self.userTypeControl.selectedSegmentIndex == 1 {
            self.setupJoin()
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        activityIndicatorView.isHidden = false
        
        if !checkTextFields() {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
            return
        }
        
        if joinRoomList.contains(groupIDField.text!) || hostRoomList.contains(groupIDField.text!) {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "You are already in the group \""+self.groupIDField.text!+"\"")
            return
        }
        
        self.view.endEditing(true)

        if host {
            
            // Firebase check room id
            // Firebase create room id
            // Firebase join room with uid as key and wishlist as children
            
            db.collection("rooms").document(groupIDField.text!).getDocument(completion: { (querySnapshot, err) in
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if !querySnapshot!.exists {
                        db.collection("rooms").document(self.groupIDField.text!).setData([user.uid:[], "locked":false, "host":user.uid]) { err in
                            if let err = err {
                                self.activityIndicatorView.isHidden = true
                                createAlert(view: self, title: "Error", message: err.localizedDescription)
                            } else {
                                db.collection("users").document(user.uid).updateData(["userdata.host": FieldValue.arrayUnion([self.groupIDField.text!])]) { (err) in
                                    if let err = err {
                                        self.activityIndicatorView.isHidden = true
                                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                                    } else {
                                        // Segue to home
                                        self.roomID = self.groupIDField.text!
                                        self.performSegue(withIdentifier: "mainToHome", sender: self)
                                    }
                                }
                                
                            }
                        }
                    }
                    if let data = querySnapshot?.data() {
                        if data.count != 0 {
                            self.activityIndicatorView.isHidden = true
                            createAlert(view: self, title: "Group already exists", message: "Please choose a new Group ID")
                        }
                    }
                }
            })
            
        } else if join {
            
            // Firebase check if room exists
            // Firebase download people data
            
            db.collection("rooms").document(groupIDField.text!).getDocument(completion: { (querySnapshot, err) in
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    let data = querySnapshot!.data()!
                    if data.count != 0 {
                        for key in data.keys {
                            if key != "locked" && key != user.uid {
                                let usrUID = key
                                if usrUID != "host" {
                                    let usrList = data[key] as! [String]
                                    dataGroup.append([usrUID:usrList])
                                }
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
                                    
                                    if !host {
                                        let personWishlist = usr[usrUID] as! [String]
                                        let person = Person(name: personName)
                                        person.setWishList(list: personWishlist)
                                        userGroup.append(person)
                                    }

                                } else {
                                    print(usrUID+" does not exist")
                                }
                            }
                        }
                        
                        db.collection("rooms").document(self.groupIDField.text!).updateData([user.uid:[]]) { err in
                                if let err = err {
                                    self.activityIndicatorView.isHidden = true
                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                } else {
                                    db.collection("users").document(user.uid).updateData(["userdata.rooms" : FieldValue.arrayUnion([self.groupIDField.text!])]) { (err) in
                                        if let err = err {
                                            self.activityIndicatorView.isHidden = true
                                            createAlert(view: self, title: "Error", message: err.localizedDescription)
                                        } else {
                                            // Segue to home
                                            self.roomID = self.groupIDField.text!
                                            self.performSegue(withIdentifier: "mainToHome", sender: self)
                                        }
                                    }
                                }
                        }
                    } else {
                        self.activityIndicatorView.isHidden = true
                        createAlert(view: self, title: "Group does not exist", message: "Please check Group ID")
                    }
                }
            })
            
        }
    }
    
    func setupHost() {
        self.titleText.text = "Host"
        self.submitButton.setTitle("Create", for: .normal)
        host = true
        join = false
        userTypeControl.tintColor = UIColor.blue
        userTypeControl.selectedSegmentTintColor = UIColor.blue
        submitButton.backgroundColor = .blue
    }
    
    func setupJoin() {
        self.titleText.text = "Join"
        host = false
        join = true
        userTypeControl.tintColor = UIColor.red
        userTypeControl.selectedSegmentTintColor = UIColor.red
        submitButton.backgroundColor = .red
        self.submitButton.setTitle("Join", for: .normal)
    }
    
    func checkTextFields() -> Bool {
        return groupIDField.text != ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainToHome" {
            let controller = (segue.destination as! UINavigationController).viewControllers[0] as! ViewController
            controller.roomID = self.roomID
            controller.setRoomDataTimer()
            controller.checkRoom()
        }
    }
    
}

func createAlert(view: UIViewController, title: String?, message: String?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(action)
    view.present(alert, animated: true, completion: nil)
}

func createAlert(view: UIViewController, title: String?, message: String?, completion: @escaping (Bool) -> ()) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .default) { (action) in
        completion(true)
    }
    alert.addAction(action)
    view.present(alert, animated: true, completion: nil)
}
