//
//  SettingsViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 12/3/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    var firstField: UITextField!
    var lastField: UITextField!
    var nameAlert: UIAlertController!
    var emailField: UITextField!
    var emailAlert: UIAlertController!
    var currentPWField: UITextField!
    var newPWField: UITextField!
    var confirmPWField: UITextField!
    var pwAlert: UIAlertController!
    
    override func viewDidLoad() {
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction)), animated: true)
        tableView.keyboardDismissMode = .onDrag
        nameButton.setTitle(userData["first"]! + " " + userData["last"]!, for: .normal)
        emailButton.setTitle(userData["email"]!, for: .normal)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    @IBAction func changeName(_ sender: Any) {
        nameAlert = UIAlertController(title: "Change Name", message: nil, preferredStyle: .alert)
        nameAlert.addTextField()
        nameAlert.addTextField()
        firstField = nameAlert.textFields![0]
        firstField.autocapitalizationType = .words
        firstField.returnKeyType = .next
        firstField.placeholder = "First Name"
        lastField = nameAlert.textFields![1]
        lastField.autocapitalizationType = .words
        lastField.returnKeyType = .done
        lastField.placeholder = "Last Name"
        nameAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        nameAlert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (action) in
            if self.firstField.text != "" && self.lastField.text != "" {
                db.collection("users").document(user.uid).updateData(["userdata.first" : self.firstField.text!, "userdata.last" : self.lastField.text!]) { (err) in
                    
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) {
                            (complete) in
                            self.present(self.nameAlert, animated: true, completion: nil)
                        }
                    } else {
                        userData["first"] = self.firstField.text!
                        userData["last"] = self.lastField.text!
                        self.nameButton.setTitle(self.firstField.text! + " " + self.lastField.text!, for: .normal)
                    }
                    
                }
            } else {
                createAlert(view: self, title: "Error", message: "Fields cannot be blank") { (complete) in
                    self.present(self.nameAlert, animated: true, completion: nil)
                }
            }
        }))
        self.present(nameAlert, animated: true, completion: nil)
    }
    
    @IBAction func changeEmail(_ sender: Any) {
        emailAlert = UIAlertController(title: "Change Email", message: nil, preferredStyle: .alert)
        emailAlert.addTextField()
        emailField = emailAlert.textFields![0]
        emailField.placeholder = "Email"
        emailField.returnKeyType = .done
        emailAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        emailAlert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (action) in
            if self.emailField.text != "" {
                user.updateEmail(to: self.emailField.text!, completion: { (err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                            self.present(self.emailAlert, animated: true, completion: nil)
                        }
                    } else {
                        db.collection("users").document(user.uid).updateData(["userdata.email" : self.emailField.text!]) { (err) in
                            if let err = err {
                                createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                                    self.present(self.emailAlert, animated: true, completion: nil)
                                }
                            } else {
                                userData["email"] = self.emailField.text!
                                self.emailButton.setTitle(self.emailField.text!, for: .normal)
                            }
                        }
                    }
                    
                })
                
            } else {
                createAlert(view: self, title: "Error", message: "Fields cannot be blank") { (complete) in
                    self.present(self.emailAlert, animated: true, completion: nil)
                }
            }
        }))
        self.present(emailAlert, animated: true, completion: nil)
        
    }
    
    @IBAction func changePassword(_ sender: Any) {
        pwAlert = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
        pwAlert.addTextField()
        currentPWField = pwAlert.textFields![0]
        currentPWField.placeholder = "Current Password"
        currentPWField.returnKeyType = .next
        currentPWField.isSecureTextEntry = true
        currentPWField.textContentType = .password
        pwAlert.addTextField()
        newPWField = pwAlert.textFields![1]
        newPWField.placeholder = "New Password"
        newPWField.returnKeyType = .next
        newPWField.isSecureTextEntry = true
        newPWField.textContentType = .password
        pwAlert.addTextField()
        confirmPWField = pwAlert.textFields![2]
        confirmPWField.placeholder = "Confirm New Password"
        confirmPWField.returnKeyType = .done
        confirmPWField.isSecureTextEntry = true
        confirmPWField.textContentType = .password
        pwAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        pwAlert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (action) in
            if self.currentPWField.text != "" && self.newPWField.text != "" && self.confirmPWField.text != "" {
                
                let credential = EmailAuthProvider.credential(withEmail: userData["email"]!, password: self.currentPWField.text!)
                user.reauthenticate(with: credential) { (data, err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                            self.present(self.pwAlert, animated: true, completion: nil)
                        }
                    } else if self.newPWField.text! != self.confirmPWField.text! {
                        createAlert(view: self, title: "Error", message: "Second and third password fields do not match") { (complete) in
                            self.present(self.pwAlert, animated: true, completion: nil)
                        }
                    } else {
                        user.updatePassword(to: self.confirmPWField.text!) { (err) in
                            if let err = err {
                                createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                                    self.present(self.pwAlert, animated: true, completion: nil)
                                }
                            } else {
                                
                            }
                        }
                    }
                }
                
            } else {
                createAlert(view: self, title: "Error", message: "Fields cannot be blank") { (complete) in
                    self.present(self.pwAlert, animated: true, completion: nil)
                }
            }
        }))
        self.present(pwAlert, animated: true, completion: nil)    }
    
    @IBAction func reportAction(_ sender: Any) {
        let textView: UITextView!
        
        let alert = UIAlertController(title: "Report", message: "Tell us what happened", preferredStyle: .alert)
        textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let controller = UIViewController()

        textView.frame = controller.view.frame
        textView.font = .systemFont(ofSize: 16)
        controller.view.addSubview(textView)

        alert.setValue(controller, forKey: "contentViewController")

        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.height * 0.4)
        
        let width: NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.width * 0.8)
        
        alert.view.addConstraint(height)
        alert.view.addConstraint(width)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            if textView.text == "" {
                createAlert(view: self, title: "Error", message: "Text field cannot be blank") { (complete) in
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM-d-yyyy_h:mm:ss_a"
                let data = [formatter.string(from: Date()) : ["name: ":userData["first"]! + " " + userData["last"]!, "email":userData["email"], "report":textView.text!]]
                db.collection("reports").document(user.uid).setData(data, merge: true, completion: { (err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        let alert2 = UIAlertController(title: "Thank You", message: "Your report has been submitted", preferredStyle: .alert)
                        alert2.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert2, animated: true, completion: nil)
                    }
                })
            }
            
        }))

        present(alert, animated: true, completion: nil)
        textView.becomeFirstResponder()
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        let deleteAlert = UIAlertController(title: "Are you sure?", message: "All groups you are currently hosting will be deleted as well", preferredStyle: .alert)
        deleteAlert.addTextField()
        deleteAlert.textFields![0].placeholder = "Enter Password"
        deleteAlert.textFields![0].textContentType = .password
        deleteAlert.textFields![0].isSecureTextEntry = true
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        deleteAlert.addAction(UIAlertAction(title: "Delete Account", style: .destructive, handler: { (action) in
            if deleteAlert.textFields![0].text! == "" {
                createAlert(view: self, title: "Error", message: "Text field cannot be blank") { (complete) in
                    self.present(deleteAlert, animated: true, completion: nil)
                }
            } else {
                let credential = EmailAuthProvider.credential(withEmail: userData["email"]!, password: deleteAlert.textFields![0].text!)
                user.reauthenticate(with: credential) { (resut, err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                            self.present(deleteAlert, animated: true, completion: nil)
                        }
                    } else {
                        self.deleteAccount()
                    }
                }
            }
        }))
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteAccount() {
        var roomIDs: [String] = []
        db.collection("users").document(user.uid).getDocument { (doc, err) in
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
            } else {
                if let data = doc?.data() {
                    let userdata = data["userdata"] as! [String:Any]
                    let hostdata = userdata["host"] as! [String]
                    if hostdata.count != 0 {
                        roomIDs = hostdata
                        // Delete rooms the user hosted and then delete user and the delete auth
                        for room in roomIDs {
                            db.collection("rooms").document(room).delete { (err) in
                                if let err = err {
                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                } else {
                                    db.collection("users").document(user.uid).delete { (err) in
                                        if let err = err {
                                            createAlert(view: self, title: "Error", message: err.localizedDescription)
                                        } else {
                                            
                                            Auth.auth().currentUser?.delete(completion: { (err) in
                                                if let err = err {
                                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                                } else {
                                                    userData = [:]
                                                    hostRoomList = []
                                                    joinRoomList = []
                                                    user = nil
                                                    wishlist = []
                                                    userGroup = []
                                                    dataGroup = []
                                                    defaults.removeObject(forKey: "currentRoom")
                                                    createAlert(view: self, title: "Success", message: "Account successfully deleted") { (complete) in
                                                        self.performSegue(withIdentifier: "deleteSegue", sender: self)
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    createAlert(view: self, title: "Error", message: "Please try again later")
                }
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    @objc func doneAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
