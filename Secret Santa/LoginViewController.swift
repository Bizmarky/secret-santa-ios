//
//  LoginViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SetupViewController {
            if segue.identifier == "hostSegue" {
                controller.host = true
            } else if segue.identifier == "joinSegue" {
                controller.join = true
            }
        }
    }
    
}
