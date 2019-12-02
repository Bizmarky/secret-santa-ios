//
//  InitialViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 12/1/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import FirebaseAuth

class InitialViewController: UIViewController {
    
    var timeOut: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timeOut = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(timeOutFunc), userInfo: nil, repeats: false)
        
    }
    
    @objc func timeOutFunc() {
        print("Timeout")
        self.performSegue(withIdentifier: "initToLogin", sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Auth.auth().currentUser?.reload(completion: { (err) in
            self.timeOut.invalidate()
            if let err = err {
                print(err)
                self.performSegue(withIdentifier: "initToLogin", sender: self)
            } else {
                user = Auth.auth().currentUser
                self.performSegue(withIdentifier: "initToMain", sender: self)
            }
        })
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.navigationItem.hidesBackButton = true
    }
    
}
