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
    
    var pwAlert: UIAlertController!
    
    @IBAction func passwordAction(_ sender: Any) {
        
        self.present(pwAlert, animated: true, completion: nil)
        
    }
    
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
        self.setupToHideKeyboardOnTapOnView()
        pwAlert = UIAlertController(title: "Reset Password", message: "Please enter your email below", preferredStyle: .alert)
        pwAlert.addTextField()
        pwAlert.textFields![0].keyboardType = .emailAddress
        pwAlert.textFields![0].placeholder = "Email"
        pwAlert.textFields![0].clearButtonMode = .whileEditing
        pwAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        pwAlert.addAction(UIAlertAction(title: "Reset Password", style: .default, handler: { (action) in
            let field = self.pwAlert.textFields![0]
            if field.text! != "" {
                Auth.auth().sendPasswordReset(withEmail: field.text!) { (err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                    } else {
                        createAlert(view: self, title: "Success", message: "Password reset email has been sent to "+field.text!)
                    }
                }
            } else {
                createAlert(view: self, title: "Error", message: "Text field cannot be blank") { (complete) in
                    self.present(self.pwAlert, animated: true, completion: nil)
                }
            }
        }))
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
