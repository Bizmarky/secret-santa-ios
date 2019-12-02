//
//  RoomDisplayViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 12/2/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class RoomDisplayViewController: UITableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0
        if !hostRoomList.isEmpty {
            sections += 1
        }
        if !joinRoomList.isEmpty {
            sections += 1
        }
        return sections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        
        if section == 0 {
            
            if !hostRoomList.isEmpty {
                count = hostRoomList.count
            } else if !joinRoomList.isEmpty {
                count = joinRoomList.count
            }
            
        } else {
            count = joinRoomList.count
        }
        
        return count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell2")
        
        if indexPath.section == 0 {
            if !hostRoomList.isEmpty {
                cell.textLabel?.text = hostRoomList[indexPath.row]
            } else if !joinRoomList.isEmpty {
                cell.textLabel?.text = joinRoomList[indexPath.row]
            }
        } else {
            cell.textLabel?.text = joinRoomList[indexPath.row]
        }
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectRoom(ID: (tableView.cellForRow(at: indexPath)?.textLabel?.text)!)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func selectRoom(ID: String) {
        let presenter = (presentingViewController as! UINavigationController).viewControllers[0] as! ViewController
        presenter.roomID = ID
        dismiss(animated: true) {
            presenter.activityIndicatorView.isHidden = false
            presenter.getRoomData()
        }
    }
    
}
