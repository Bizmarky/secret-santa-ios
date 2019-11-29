//
//  User.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

var wishlist: [String]!
let db = Firestore.firestore()
var uid: String!
var ref: DocumentReference? = nil
var userGroup: [Person]!
