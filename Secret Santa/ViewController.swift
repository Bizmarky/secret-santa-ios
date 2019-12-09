//
//  ViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userGroup.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "personCell", for: indexPath) as? PersonCell else {
            fatalError("Unable to dequeue PersonCell")
        }
        let rand = arc4random_uniform(2)
        let imgName = "santa\(rand).png"
        cell.imageView.image = UIImage(named: imgName)
        cell.user = userGroup[indexPath.row]
        cell.name.text = userGroup[indexPath.row].getName()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellTap(person: userGroup[indexPath.row])
    }
    
    func cellTap(person: Person) {
        print(person.getName())
    }
    
    @IBOutlet weak var groupCollectionView: UICollectionView!
    
    var isHost: Bool!
    let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    var roomID: String!
    var roomName: String!
    var roomDate: Date!
    var roomHost: String!
    var listDownloadTimer: Timer!
    var activityTimer: Timer!
    var errorDismiss: Bool!
    var viewAppeared = false
    var roomDataTimer: Timer!
    var delete = false
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func menuAction(_ sender: Any) {
        
        self.present(menuAlert, animated: true, completion: nil)
        
    }
    
    @objc func getLists() {
        if hostRoomList.isEmpty && joinRoomList.isEmpty {
            checkRoom()
        }
    }
    
    func setRoomDataTimer() {
        roomDataTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
            if self.viewAppeared {
                self.roomDataTimer.invalidate()
                self.getRoomData()
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listDownloadTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getLists), userInfo: nil, repeats: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        groupCollectionView.delegate = self
        groupCollectionView.dataSource = self
        
        errorDismiss = false
        setupMenuActionSheet()
        let bar = self.navigationController?.navigationBar
        let tapView = UIView(frame: CGRect(x: (bar?.center.x)!-50, y: (bar?.center.y)!-20, width: 100, height: 40))
        tapView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(showGroups))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        self.navigationController?.navigationBar.addSubview(tapView)
        tapView.addGestureRecognizer(tap)
        
        viewAppeared = true
//        pairPeople()
    }
    
    func checkRoom() {
        hostRoomList = []
        joinRoomList = []
        roomNameMap = [:]
        db.collection("users").document(user.uid).getDocument { (document, err) in
            if let err = err {
                print(err)
            } else {
                let data = document?.data()?.values.first as! [String:Any]
                
                let dataRooms = data["rooms"] as! [String]
                let hostRooms = data["host"] as! [String]
                
                for roomID in hostRooms {
                    let room = roomID.lowercased()
                    hostRoomList.append(room)
                    db.collection("rooms").document(room).getDocument { (doc, err) in
                        if let err = err {
                            print(err)
                        } else {
                            let data = doc?.data()!
                            let name = data!["name"] as! String
                            roomNameMap[room] = name
                        }
                    }
                }
                for roomID in dataRooms {
                    let room = roomID.lowercased()
                    if !hostRoomList.contains(room) {
                        joinRoomList.append(room)
                        db.collection("rooms").document(room).getDocument { (doc, err) in
                            if let err = err {
                                print(err)
                            } else {
                                let data = doc?.data()!
                                let name = data!["name"] as! String
                                roomNameMap[room] = name
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func showGroups() {
        performSegue(withIdentifier: "roomDisplay", sender: self)
//        let rd = RoomDisplayViewController()
//        self.present(rd, animated: true, completion: nil)
    }
    
    func setupMenuActionSheet() {
        
        menuAlert.addAction(UIAlertAction(title: "Groups", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "roomDisplay", sender: self)
//            let rd = RoomDisplayViewController()
//            self.present(rd, animated: true, completion: nil)
        }))
        menuAlert.addAction(UIAlertAction(title: "Create/Join", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "homeToMain", sender: self)
        }))
        menuAlert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "settingsSegue", sender: self)
        }))
        menuAlert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { (action) in
            self.logoutAction()
        }))
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
    }
    
    func logoutAction() {
        if !delete {
            let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                
                self.activityIndicatorView.isHidden = false

                let firebaseAuth = Auth.auth()
                
                do {
                    try firebaseAuth.signOut()
                    user = nil
                    self.performSegue(withIdentifier: "logoutSegue", sender: self)
                } catch let signOutError as NSError {
                    createAlert(view: self, title: "Error", message: signOutError.localizedDescription)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "logoutSegue", sender: self)
        }
    }
    
    func getRoomData() {

        userGroup = []
        
        if roomID == "" {
            performSegue(withIdentifier: "roomDisplay", sender: self)
//            let rd = RoomDisplayViewController()
//            self.present(rd, animated: true, completion: nil)
        } else {
            db.collection("rooms").document(roomID).getDocument { (querySnapshot, err) in
                if let err = err {
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if let data = querySnapshot?.data() {
                        if data.count != 0 {
                            for key in data.keys {
                                if key != "locked" {
                                    let usrUID = key
                                    var usrList: Any!
                                    if usrUID == "host" || usrUID == "name" {
                                        usrList = data[key] as! String
                                    } else if usrUID == "date" {
                                        usrList = data[key] as! TimeInterval
                                    } else {
                                        usrList = data[key] as! [String]
                                    }
                                    
                                    dataGroup.append([usrUID:usrList!])
                                }
                            }
                            var reloadTimer: Timer!
                            for usr in dataGroup {
                                var host = false
                                var name = false
                                var date = false
                                var usrUID = usr.keys.first!
                                if usrUID == "host" {
                                    host = true
                                    usrUID = usr[usrUID] as! String
                                } else if usrUID == "name" {
                                    name = true
                                    self.roomName = (usr[usrUID] as! String)
                                } else if usrUID == "date" {
                                    date = true
                                    self.roomDate = Date(timeIntervalSince1970: usr[usrUID] as! TimeInterval)
                                }
                                db.collection("users").document(usrUID).getDocument { (document, err) in
                                    
                                    if let err = err {
                                        print(err)
                                    } else  if let _ = document, document!.exists {
                                        let rawdata = document!.data()!
                                        let data = rawdata["userdata"] as! [String:Any]
                                        let personName = (data["first"] as! String) + " " + (data["last"] as! String)

                                        if host {
                                            self.roomHost = personName
                                        } else {
                                            let personWishlist = usr[usrUID] as! [String]
                                            if usrUID == user.uid {
                                                wishlist = personWishlist
                                            } else {
                                                let person = Person(name: personName)
                                                person.setWishList(list: personWishlist)
                                                userGroup.append(person)
                                                if reloadTimer != nil {
                                                    reloadTimer.invalidate()
                                                    
                                                }
                                                reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
                                                    reloadTimer.invalidate()
                                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                                                        self.groupCollectionView.reloadData()
                                                    }
                                                })
                                            }
                                        }
                                    } else if !name && !date {
                                        print(usrUID+" does not exist")
                                    }
                                }
                                
                            }
                            self.navigationItem.title = self.roomName
                            print("ID: "+self.roomID)
                            print("Name: "+self.roomName)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM d, yyyy h:mm a"
                            print("Date: "+formatter.string(from: self.roomDate))
                            self.activityTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                                if self.activityIndicatorView != nil {
                                    self.activityTimer.invalidate()
                                    self.activityIndicatorView.isHidden = true
                                }
                            })
                            defaults.set(self.roomID, forKey: "currentRoom")
                        }
                    } else {
                        var count = 0
                        for room in hostRoomList {
                            if room == self.roomID {
                                hostRoomList.remove(at: count)
                            }
                            count += 1
                        }
                        
                        count = 0
                        for room in joinRoomList {
                            if room == self.roomID {
                                joinRoomList.remove(at: count)
                            }
                            count += 1
                        }
                        if hostRoomList.count + joinRoomList.count == 0 {
                            self.errorDismiss = true
                            self.performSegue(withIdentifier: "homeToMain", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "roomDisplay", sender: self)
                        }
                    }
                }
            }
        
        }

        
        // Get host
        // Get users
        // Get room name
        
//        pairPeople()
        
    }
    
    // Assigns each person with their secret santa
    
    func pairPeople() {
        let count = userGroup.count
        var remaining = [Int]()
        
        for i in 0..<count {
            remaining.append(i)
        }
                
        for i in 0..<count {
            var num = Int(arc4random_uniform(UInt32(remaining.count)))
            
            while (userGroup[num] == userGroup[i]) {
                num = Int(arc4random_uniform(UInt32(count)))
            }
                        
            var index = 0
            
            for j in 0..<remaining.count {
                if num == j {
                    index = j
                }
            }
            
            let secret = remaining[index]
            let secretP = userGroup[secret]
            userGroup[i].assign(person: secretP)
            
            remaining.remove(at: index)

        }
                        
//        Print who is paired with who
        
        for person in userGroup {
            print(person.getName() + " is assigned to " + person.getSecretPerson()!.getName())
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToWish" {
            let controller = segue.destination as! WishlistViewController
            controller.roomID = self.roomID
        } else if segue.identifier == "homeToMain" {
            let controller = (segue.destination as! UINavigationController).viewControllers[0] as! SetupViewController
            controller.fromHome = !errorDismiss
        }
    }

}

class PersonCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    var user: Person!
}
