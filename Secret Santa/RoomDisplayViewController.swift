//
//  RoomDisplayViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 12/2/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit

class RoomDisplayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var roomTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.roomTableView.delegate = self
        self.roomTableView.dataSource = self
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0
        if !hostRoomList.isEmpty {
            sections += 1
        }
        if !joinRoomList.isEmpty {
            sections += 1
        }
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title = ""
        
        if section == 0 {
            
            if !hostRoomList.isEmpty {
                title = "Hosting"
            } else if !joinRoomList.isEmpty {
                title = "Joined"
            }
            
        } else {
            title = "Joined"
        }
        
        return title
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
        cell.textLabel?.font = .boldSystemFont(ofSize: 16)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectRoom(ID: (tableView.cellForRow(at: indexPath)?.textLabel?.text)!)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func selectRoom(ID: String) {
        let presenter = (presentingViewController as! UINavigationController).viewControllers[0] as! ViewController
        presenter.roomID = ID
        dismiss(animated: true) {
            presenter.getRoomData()
        }
    }
    
}
