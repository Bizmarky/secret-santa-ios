//
//  SignUpViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/30/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var firstNameField: UITextField!
    
    @IBOutlet weak var lastNameField: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.layer.cornerRadius = nextButton.frame.height/4
        
        firstNameField.translatesAutoresizingMaskIntoConstraints = false
        firstNameField.layer.cornerRadius = firstNameField.frame.height/4
        
        lastNameField.translatesAutoresizingMaskIntoConstraints = false
        lastNameField.layer.cornerRadius = lastNameField.frame.height/4
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        if checkTextFields() {
            self.performSegue(withIdentifier: "signUpSegue", sender: self)
        } else {
            createAlert(title: "Error", message: "Text fields cannot be blank")
        }
        
    }
    
    func checkTextFields() -> Bool {
        return firstNameField.text != "" && lastNameField.text != ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(firstNameField.tag) {
            lastNameField.becomeFirstResponder()
        } else {
            resignFirstResponder()
            nextAction(self)
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signUpSegue" {
            let controller = segue.destination as! SecondSignUpViewController
            controller.firstName = self.firstNameField.text!
            controller.lastName = self.lastNameField.text!
        }
    }
    
}
