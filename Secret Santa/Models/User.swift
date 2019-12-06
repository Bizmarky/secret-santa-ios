//
//  User.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

var wishlist: [String]!
let db = Firestore.firestore()
var userGroup: [Person]!
var dataGroup: [[String:Any]]!
var user: User!
var hostRoomList: [String]!
var joinRoomList: [String]!
var roomNameMap: [String:String]!
let defaults = UserDefaults.standard
var userData: [String:String]!
