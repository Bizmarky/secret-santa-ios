//
//  SecondSignUpViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/30/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

class SecondSignUpViewController: UIViewController, UITextFieldDelegate {
    
    
    var firstName: String!
    var lastName: String!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
        
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupToHideKeyboardOnTapOnView()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.layer.cornerRadius = emailField.frame.height/4
        
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.layer.cornerRadius = passwordField.frame.height/4
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.layer.cornerRadius = submitButton.frame.height/4
        
        emailField.becomeFirstResponder()
        
        activityIndicatorView.isHidden = true
    }
    
    @IBAction func submitAction(_ sender: Any) {
        self.view.endEditing(true)
        activityIndicatorView.isHidden = false
        if checkTextFields() {
            
//            print("First Name:\t"+firstName+"\nLast Name:\t"+lastName+"\nEmail:\t"+emailField.text!+"\nPassword:\t"+passwordField.text!)
            
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (authResult, err) in
                
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    user = authResult!.user
                    Firestore.firestore().collection("users").document(user.uid).setData(["userdata":[
                        "first":self.firstName!,
                        "last":self.lastName!,
                        "email":self.emailField.text!,
                        "rooms":[],
                        "host":[]
                        ]]) { (err) in
                         
                            if let err = err {
                                self.activityIndicatorView.isHidden = true
                                createAlert(view: self, title: "Error", message: err.localizedDescription)
                            } else {
                                authResult!.user.sendEmailVerification { (err) in
                                    if let err = err {
                                        self.activityIndicatorView.isHidden = true
                                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                                    } else {
                                        createAlert(view: self, title: "Success", message: "Account successfully created!\n A verification email has been sent to "+self.emailField.text!, completion: { (complete) in
                                            // Segue to main
                                            self.performSegue(withIdentifier: "setupToMain", sender: self)
                                        })
                                    }
                                }
                            }
                    }
                }
            }
        } else {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(emailField) {
            passwordField.becomeFirstResponder()
        } else {
            resignFirstResponder()
            submitAction(self)
        }
        return true
    }
    
    func checkTextFields() -> Bool {
        return emailField.text != "" && passwordField.text != ""
    }
    
}
