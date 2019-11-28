//
//  WishlistViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class WishlistViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlist.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! wishlistTableViewCell
        cell.textField.text = wishlist[indexPath.row]
        cell.tag = indexPath.row
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            wishlist.remove(at: indexPath.row)
            tableView.reloadData()
        }
        
        if editingStyle == .insert {
            wishlist.insert((tableView.cellForRow(at: indexPath)?.textLabel!.text!)!, at: indexPath.row)
        }
        
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem)), animated: true)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveAndExit)), animated: true)
        
        tableView.register(wishlistTableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.keyboardDismissMode = .onDrag
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func addItem() {
        wishlist.append("")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.tableView.reloadData()
            (self.tableView.cellForRow(at: IndexPath(row: wishlist.count-1, section: 0)) as! wishlistTableViewCell).textField.becomeFirstResponder()
        }
    }
    
    @objc func keyboardWillHide() {
        var indexes = [IndexPath]()
        var offset = 0

        for i in 0..<wishlist.count {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! wishlistTableViewCell
            if cell.textField.text! == "" {
                indexes.append(IndexPath(row: i, section: 0))
                wishlist.remove(at: i)
                offset += 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.tableView.deleteRows(at: indexes, with: .top)
            self.tableView.reloadData()
        }
        
    }
    
    @objc func saveAndExit(barButton: UIBarButtonItem) {
        // Save to firebase and go back
        
        self.navigationController?.popViewController(animated: true)
    }
    
}
