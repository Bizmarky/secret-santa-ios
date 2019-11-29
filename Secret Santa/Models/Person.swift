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
    var id = UUID()
    var personWishList: [String]!
    
    init(name: String) {
        self.name = name
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
    
}

extension Person: Equatable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
}
