//
//  WishlistTableViewCell.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class wishlistTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    var textField: UITextField!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.textField = UITextField(frame: CGRect(origin: CGPoint(x: 16, y: 0), size: CGSize(width: self.frame.size.width + 56, height: self.frame.size.height)))
        self.textField.delegate = self
        self.textField.clearButtonMode = .whileEditing
        self.textLabel?.removeFromSuperview()
        contentView.addSubview(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        wishlist[self.tag] = self.textField.text!
    }
    
    func getText() -> String {
        return self.textField.text!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
