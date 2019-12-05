//
//  LoginViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
        
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.layer.cornerRadius = loginButton.frame.height/4
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.layer.cornerRadius = emailTextField.frame.height/4
        
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.layer.cornerRadius = passwordTextField.frame.height/4
        
        emailTextField.becomeFirstResponder()
        
        activityIndicatorView.isHidden = true
                
    }
    
    @objc func deletedAccount() {
        createAlert(view: self, title: "Success", message: "Account successfully deleted")
    }
    
    @IBAction func loginAction(_ sender: Any) {
        self.view.endEditing(true)
        activityIndicatorView.isHidden = false
        if checkTextFields() {
//            print("Email:\t"+emailTextField.text!+"\nPassword:\t"+passwordTextField.text!)
            
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authResult, err) in
                
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    user = authResult!.user
                    // Segeue to main
                    self.performSegue(withIdentifier: "loginToMain", sender: self)
                }
                
            }
            
        } else {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(emailTextField) {
            passwordTextField.becomeFirstResponder()
        } else {
            resignFirstResponder()
            loginAction(self)
        }
        return true
    }
    
    func checkTextFields() -> Bool {
        return emailTextField.text != "" && passwordTextField.text != ""
    }
    
}
