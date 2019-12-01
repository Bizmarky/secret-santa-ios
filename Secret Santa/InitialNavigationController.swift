//
//  InitialNavigationController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 12/1/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import FirebaseAuth

class InitialNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rootNav = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Auth.auth().currentUser?.reload(completion: { (err) in
            if let err = err {
                print(err)
                self.performSegue(withIdentifier: "initToLogin", sender: self)
            } else {
                user = Auth.auth().currentUser
                self.performSegue(withIdentifier: "initToMain", sender: self)
            }
        })
        
//        if Auth.auth().currentUser != nil {
//            user = Auth.auth().currentUser
//            // segue to main
//            performSegue(withIdentifier: "initToMain", sender: self)
//        } else {
//            // segue to login
//            performSegue(withIdentifier: "initToLogin", sender: self)
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.navigationItem.hidesBackButton = true
    }
    
}
