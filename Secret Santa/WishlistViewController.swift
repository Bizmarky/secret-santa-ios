//
//  WishlistViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

class WishlistViewController: UITableViewController, UITextFieldDelegate {
    
    var roomID: String!
    var done: Bool!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlist.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! wishlistTableViewCell
        cell.textField.delegate = self
        cell.textField.text = wishlist[indexPath.row]
        cell.textField.returnKeyType = .next
        cell.textField.tag = indexPath.row
        cell.isUserInteractionEnabled = true
        cell.tag = indexPath.row
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
                
        if editingStyle == .delete {
            wishlist.remove(at: indexPath.row)
            saveWishlist()
        }
        
        if editingStyle == .insert {
            wishlist.insert((tableView.cellForRow(at: indexPath)?.textLabel!.text!)!, at: indexPath.row)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        done = false
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem)), animated: true)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveAndExit)), animated: true)
        
        tableView.register(wishlistTableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        tableView.keyboardDismissMode = .onDrag
    }
    
    @objc func addItem() {
        wishlist.append("")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.tableView.reloadData()
            (self.tableView.cellForRow(at: IndexPath(row: wishlist.count-1, section: 0)) as! wishlistTableViewCell).textField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag < wishlist.count-1 {
            (tableView.cellForRow(at: IndexPath(row: textField.tag+1, section: 0)) as! wishlistTableViewCell).textField.becomeFirstResponder()
        }
        if textField.tag == wishlist.count-1 {
            if textField.text != "" {
                self.addItem()
            }
        }
        return true
    }
    
    func saveWishlist() {
        
        var tempList: [String] = []
        
        for c in 0..<tableView.numberOfRows(inSection: 0) {
            let cell = tableView.cellForRow(at: IndexPath(row: c, section: 0)) as! wishlistTableViewCell
            tempList.append(cell.getText())
        }
        
        wishlist = tempList
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            DispatchQueue.main.async {
                wishlist.remove(at: textField.tag)
                self.tableView.deleteRows(at: [IndexPath(row: textField.tag, section: 0)], with: .top)
                self.saveWishlist()
                self.tableView.reloadData()
            }
        } else {
            wishlist[textField.tag] = textField.text!
        }
        return true
    }
    
    func updateFirestore() {
        
        Firestore.firestore().collection("rooms").document(roomID).updateData([user.uid : wishlist!]) { (err) in
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
            }
        }
        
    }
    
    @objc func saveAndExit(barButton: UIBarButtonItem) {
        // Save to firebase and go back
        done = true
        saveWishlist()
        updateFirestore()
        self.navigationController?.popViewController(animated: true)
    }
    
}
