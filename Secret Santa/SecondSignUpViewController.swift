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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.layer.cornerRadius = emailField.frame.height/4
        
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.layer.cornerRadius = passwordField.frame.height/4
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.layer.cornerRadius = submitButton.frame.height/4
    }
    
    @IBAction func submitAction(_ sender: Any) {
        if checkTextFields() {
            print("First Name:\t"+firstName+"\nLast Name:\t"+lastName+"\nEmail:\t"+emailField.text!+"\nPassword:\t"+passwordField.text!)
        } else {
            createAlert(title: "Error", message: "Text fields cannot be blank")
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(emailField.tag) {
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
