//
//  SetupViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
//import Firebase

class SetupViewController: UIViewController {
    
    var host: Bool!
    var join: Bool!
    var titleText: UILabel!
    
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    
    @IBOutlet weak var groupIDField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func submitButton(_sender: Any){
        performSegue(withIdentifier: "SetupToNavigation", sender: self)
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
            self.createAlert(title: "Error", message: "Text fields cannot be blank")
        }
        
        if host {
            // Firebase check room id
            // Firebase create room id
            // Firebase join room with uid as node and name and wishlist as children
        } else if join {
            // Firebase check if room exists
            // Firebase
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
    
    func createAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
}
