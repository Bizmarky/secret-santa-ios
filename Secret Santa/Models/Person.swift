//
//  Person.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation

class Person: Any {
    
    var name: String = ""
    var secretPerson: Person?
    var id = UUID().uuidString
    var personWishList: [String]!
    var host: Bool!
    
    init(name: String) {
        self.name = name
        self.host = false
    }
    
    func isHost() -> Bool {
        return self.host
    }
    
    func setHost(isHost: Bool) {
        self.host = isHost
    }
    
    func getName() -> String {
        return self.name
    }
    
    func setName(newName: String) {
        self.name = newName
    }
    
    func assign(person: Person) {
        self.secretPerson = person
    }
    
    func getSecretPerson() -> Person? {
        return self.secretPerson
    }
    
    func setWishList(list: [String]) {
        self.personWishList = list
    }
    
    func getWishList() -> [String] {
        return self.personWishList
    }
    
    func setID(newID: String) {
        self.id = newID
    }
    
    func getID() -> String {
        return self.id
    }
    
}

extension Person: Equatable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
}
