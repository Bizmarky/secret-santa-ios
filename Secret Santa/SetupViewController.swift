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

class SetupViewController: UIViewController {
    
    var host: Bool!
    var join: Bool!
    var titleText: UILabel!
    
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    
    @IBOutlet weak var groupIDField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func logoutAction(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            
            self.activityIndicatorView.isHidden = false

            let firebaseAuth = Auth.auth()
            
            do {
                try firebaseAuth.signOut()
                self.performSegue(withIdentifier: "logoutSegue", sender: self)
            } catch let signOutError as NSError {
                createAlert(view: self, title: "Error", message: signOutError.localizedDescription)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        activityIndicatorView.isHidden = true
        
    }
    
    @IBAction func userTypeAction(_ sender: Any) {
        if self.userTypeControl.selectedSegmentIndex == 0 {
            self.setupHost()
        } else if self.userTypeControl.selectedSegmentIndex == 1 {
            self.setupJoin()
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        
        if !checkTextFields() {
            createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
        }
        
        if host {
            
            // Firebase check room id
            // Firebase create room id
            // Firebase join room with uid as node and name and wishlist as children
            
            db.collection(groupIDField.text!).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if querySnapshot!.documents.count == 0 {
                        ref = db.collection(self.groupIDField.text!).addDocument(data: [
                            "name":self.nameField.text!,
                            "wishlist":[String](),
                            "host":true
                            ]) { err in
                                if let err = err {
                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                } else {
                                    uid = ref!.documentID
                                    print(uid)
                                    // Segue to next screen
//                                    performSegue(withIdentifier: "SetupToMain", sender: self)
                                }
                            }
                    } else {
                        createAlert(view: self, title: "Group already exists", message: "Please choose a new Group ID")
                    }
                }
            }
            
        } else if join {
            
            // Firebase check if room exists
            // Firebase download people data
            
            db.collection(groupIDField.text!).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if querySnapshot!.documents.count != 0 {
                        for doc in querySnapshot!.documents {
                            let data = doc.data()
                            let personName = data["name"] as! String
                            let personWishlist = data["wishlist"] as! [String]
                            
                            let person = Person(name: personName)
                            person.setWishList(list: personWishlist)
                            
                            userGroup.append(person)
                        }
                        ref = db.collection(self.groupIDField.text!).addDocument(data: [
                            "name":self.nameField.text!,
                            "wishlist":[String](),
                            "host":false
                            ]) { err in
                                if let err = err {
                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                } else {
                                    uid = ref!.documentID
                                    print(uid)
                                    // Segue to next screen
//                                    performSegue(withIdentifier: "SetupToMain", sender: self)
                                }
                        }
                    } else {
                        createAlert(view: self, title: "Group does not exist", message: "Please check Group ID")
                    }
                }
            }
            
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
        return groupIDField.text != "" && nameField.text != ""
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
