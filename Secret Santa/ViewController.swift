//
//  ViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/27/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var groupCollectionView: UICollectionView!
    
    @IBOutlet weak var participantButton: UIButton!
    
    @IBOutlet weak var wishListButton: UIButton!
    
    var isHost: Bool!
    var locked: Bool!
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
    var giftExchangeTimer: Timer!
    var timerInterval = 0.2
    var listener: ListenerRegistration!
    var hostID: String!
    var pairID: String!
    var pairName: String!
    var editingRoom: Bool!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var giftExchangeLabel: UILabel!
    @IBOutlet weak var giftSublabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
                
        self.pairID = ""
        self.pairName = ""
        self.editingRoom = false
        
        participantButton.alpha = 0
        
        if self.roomID != nil {
            checkRoom()
            setRoomDataTimer()
        }
        
        participantButton.isHidden = true
        giftExchangeLabel.text = ""
        giftSublabel.text = ""
        giftExchangeTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { (timer) in
            self.updateGiftExchange()
        })
        
        groupCollectionView.delegate = self
        groupCollectionView.dataSource = self
        
        errorDismiss = false
        let bar = self.navigationController?.navigationBar
        let tapView = UIView(frame: CGRect(x: (bar?.center.x)!-50, y: (bar?.center.y)!-20, width: 100, height: 40))
        tapView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(showGroups))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        self.navigationController?.navigationBar.addSubview(tapView)
        tapView.addGestureRecognizer(tap)
        
        viewAppeared = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listDownloadTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(getLists), userInfo: nil, repeats: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userGroup.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "personCell", for: indexPath) as? PersonCell else {
            fatalError("Unable to dequeue PersonCell")
        }
        var imgName = "santa.png"
        if self.locked != nil {
            if self.locked {
                if userGroup[indexPath.row].getID() == self.pairID {
                    imgName = "present.png"
                }
            }
        }
        cell.imageView.image = UIImage(named: imgName)
        cell.user = userGroup[indexPath.row]
        cell.name.text = userGroup[indexPath.row].getName()
        cell.id = userGroup[indexPath.row].getID()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellTap(person: userGroup[indexPath.row])
    }
    
    func cellTap(person: Person) {
        let action = UIAlertController(title: person.getName(), message: nil, preferredStyle: .actionSheet)
        
        if !locked {
            if isHost {
                action.addAction(UIAlertAction(title: "Remove from group", style: .default, handler: { (action) in
                    self.removeAction(person: person)
                }))
            }
        } else {
            if person.getID() == self.pairID {
                action.addAction(UIAlertAction(title: "View Wishlist", style: .default, handler: { (action) in
                    self.viewWishlist(person: person)
                }))
            }
        }
        
        action.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (action) in
            self.reportAction(person: person)
        }))
        
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(action, animated: true, completion: nil)
    }
    
    func viewWishlist(person: Person) {
        self.performSegue(withIdentifier: "homeToWish", sender: self)
    }
    
    func removeAction(person: Person) {
        let alert = UIAlertController(title: "Confirm?", message: "Remove participant (\(person.getName()))?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (action) in
            db.collection("rooms").document(self.roomID).updateData([person.getID() : FieldValue.delete()]) { (err) in
                if let err = err {
                    createAlert(view: self, title: "OK", message: err.localizedDescription)
                } else {
                    db.collection("users").document(person.getID()).updateData(["userdata.rooms" : FieldValue.arrayRemove([self.roomID!])]) { (err) in
                        if let err = err {
                            createAlert(view: self, title: "OK", message: err.localizedDescription)
                        }
                    }
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func reportAction(person: Person) {
        let textView: UITextView!
        
        let alert = UIAlertController(title: "Report "+person.getName(), message: "Tell us what happened", preferredStyle: .alert)
        textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let controller = UIViewController()

        textView.frame = controller.view.frame
        textView.font = .systemFont(ofSize: 16)
        controller.view.addSubview(textView)

        alert.setValue(controller, forKey: "contentViewController")

        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.height * 0.4)
        
        let width: NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.width * 0.8)
        
        alert.view.addConstraint(height)
        alert.view.addConstraint(width)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            if textView.text == "" {
                createAlert(view: self, title: "Error", message: "Text field cannot be blank") { (complete) in
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM-d-yyyy_h:mm:ss_a"
                let data = [formatter.string(from: Date()) : ["name: ":userData["first"]! + " " + userData["last"]!, "email":userData["email"], "report":"Against "+person.getName()+" (\(person.getID()))\n\n"+textView.text!]]
                db.collection("reports").document(user.uid).setData(data, merge: true, completion: { (err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription) { (complete) in
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        let alert2 = UIAlertController(title: "Thank You", message: "Your report has been submitted", preferredStyle: .alert)
                        alert2.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert2, animated: true, completion: nil)
                    }
                })
            }
            
        }))

        present(alert, animated: true, completion: nil)
        textView.becomeFirstResponder()
    }
    
    @IBAction func menuAction(_ sender: Any) {
        
        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if isHost {
            let a = UIAlertAction(title: "Edit Group", style: .default, handler: { (action) in
                self.editRoom()
            })
            a.isEnabled = !self.locked
            menuAlert.addAction(a)
        }
        
        menuAlert.addAction(UIAlertAction(title: "Groups", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "roomDisplay", sender: self)
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
        
        self.present(menuAlert, animated: true, completion: nil)
        
    }
    
    @objc func getLists() {
        if hostRoomList.isEmpty && joinRoomList.isEmpty {
            checkRoom()
        }
    }
    
    func setRoomDataTimer() {
        roomDataTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { (timer) in
            if self.viewAppeared {
                self.roomDataTimer.invalidate()
                self.setupListener()
            }
        })
    }
    
    func setupHost() {
        if !locked && userGroup!.count >= 2 {
            participantButton.setTitleColor(.white, for: .normal)
            participantButton.setTitle("Start / Invite", for: .normal)
            participantButton.isUserInteractionEnabled = true
            participantButton.backgroundColor = .blue
        } else {
            if locked {
                participantButton.setTitle("Game Started", for: .normal)
                participantButton.setTitleColor(.lightGray, for: .normal)
                participantButton.isUserInteractionEnabled = false
                participantButton.backgroundColor = .gray
            } else {
                participantButton.setTitle("Invite More People", for: .normal)
                participantButton.setTitleColor(.white, for: .normal)
                participantButton.isUserInteractionEnabled = true
                participantButton.backgroundColor = .red
            }
        }
        participantButton.translatesAutoresizingMaskIntoConstraints = false
        participantButton.layer.cornerRadius = participantButton.frame.height/4
        
        UIView.animate(withDuration: 0.2) {
            self.participantButton.alpha = 1
        }
    }
    
    
    @IBAction func participantAction(_ sender: Any) {
        if isHost && !locked {
            if userGroup!.count >= 2 {
                
                let startInviteController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                startInviteController.addAction(UIAlertAction(title: "Share Invite Code", style: .default, handler: { (action) in
                    self.shareAction()
                }))
                startInviteController.addAction(UIAlertAction(title: "Start Game", style: .destructive, handler: { (action) in
                    self.pairAction()
                }))
                startInviteController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(startInviteController, animated: true, completion: nil)
                
            } else {
                self.shareAction()
            }
        }
    }
    
    func pairAction() {
        self.activityIndicatorView.isHidden = false
        self.pairPeople()
    }
    
    func shareAction() {
        let shareController = UIActivityViewController(activityItems: ["Join my secret santa group! Invite Code: "+self.roomID!+"\nApp Link"], applicationActivities: [])
        self.present(shareController, animated: true, completion: nil)
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
    
    func editRoom() {
        editingRoom = true
        self.performSegue(withIdentifier: "homeToMain", sender: self)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("VIEW DISAPPEARING")
        listener.remove()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("VIEW APPEARING")
        setupListener()
    }
    
    func setupListener() {
        if listener != nil {
            listener.remove()
            listener = nil
        }
        self.dataComplete = true
        listener = db.collection("rooms").document(roomID).addSnapshotListener({ (snapshot, err) in
            
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
                return
            }
            
            if self.dataComplete {
                self.getRoomData()
                self.checkRoom()
            }
            
//            let source = snapshot!.metadata.hasPendingWrites ? "Local" : "Server"
//            print("\(source) data: \(snapshot!.data() ?? [:])")
            
        })
//        listener = db.collection("rooms").document(roomID).addSnapshotListener({ (snapshot, err) in
//
//        })
    }
    var dataComplete = true
    func getRoomData() {
        self.dataComplete = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5) {
            userGroup = []
            dataGroup = []
            
            if self.roomID == "" {

                self.performSegue(withIdentifier: "roomDisplay", sender: self)
    //            let rd = RoomDisplayViewController()
    //            self.present(rd, animated: true, completion: nil)
            } else {
                db.collection("rooms").document(self.roomID).getDocument(completion: { (querySnapshot, err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                        return
                    } else {
                        if let data = querySnapshot?.data() {
                            if data.count != 0 {
                                if let _ = data[user.uid] as? [String] {
                                    self.locked = (data["locked"] as! Bool)
                                    if !self.locked {
                                        self.wishListButton.isUserInteractionEnabled = true
                                        self.wishListButton.setTitleColor(.systemBlue, for: .normal)
                                    } else {
                                        self.wishListButton.isUserInteractionEnabled = false
                                        self.wishListButton.setTitleColor(.gray, for: .normal)
                                        
                                    }
                                    self.isHost = (data["host"] as! String) == user.uid

                                    for key in data.keys {
                                        if key != "locked" && key != "pairs" {
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
                                                    self.hostID = usrUID
                                                } else {
                                                    let personWishlist = usr[usrUID] as! [String]
                                                    if usrUID == user.uid {
                                                        wishlist = personWishlist
                                                    } else {
                                                        let person = Person(name: personName)
                                                        person.setWishList(list: personWishlist)
                                                        person.setID(newID: usrUID)
                                                        userGroup.append(person)
//                                                        print(personName+" wishlist: ")
//                                                        print(personWishlist)
                                                    }
                                                }
                                                
                                                if reloadTimer != nil {
                                                    reloadTimer.invalidate()
                                                }
                                                reloadTimer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true, block: { (timer) in
                                                    reloadTimer.invalidate()
                                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                                                        userGroup.sort {
                                                            $0.getName() < $1.getName()
                                                            
                                                        }
                                                        if self.isHost {
                                                            self.setupHost()
                                                        } else {
                                                            UIView.animate(withDuration: 0.2) {
                                                                self.participantButton.alpha = 1
                                                            }
                                                        }
                                                        if self.locked {
                                                            self.getPair()
                                                        } else {
                                                            self.groupCollectionView.reloadData()
                                                            self.dataComplete = true
                                                        }
                                                        self.participantButton.isHidden = false
                                                    }
                                                })
                                                
                                            } else if !name && !date {
                                                print(usrUID+" does not exist")
                                            }
                                        }
                                        
                                    }
                                    
                                    for usr in userGroup {
                                        if usr.getID() == self.hostID {
                                            usr.setHost(isHost: true)
                                        }
                                    }
                                    
                                    self.navigationItem.title = self.roomName
    //                                print("ID: "+self.roomID)
    //                                print("Name: "+self.roomName)
    //                                let formatter = DateFormatter()
    //                                formatter.dateFormat = "MMM d, yyyy h:mm a"
    //                                print("Date: "+formatter.string(from: self.roomDate))
                                    
                                    self.activityTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                                        if self.activityIndicatorView != nil {
                                            self.activityTimer.invalidate()
                                            self.activityIndicatorView.isHidden = true
                                        }
                                    })
                                    defaults.set(self.roomID, forKey: "currentRoom")
                                    
                                } else {
                                    self.checkRoom()
                                    createAlert(view: self, title: "Error Loading Group", message: nil) { (complete) in
                                        if joinRoomList.count == 0 && hostRoomList.count == 0 {
                                            self.errorDismiss = true
                                            self.performSegue(withIdentifier: "homeToMain", sender: self)
                                        } else {
                                            self.performSegue(withIdentifier: "roomDisplay", sender: self)
                                        }
                                    }
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
                                self.dataComplete = true
                            }
                        }
                    }
                })
            }
        }
    }
    
    func getPair() {
        db.collection("rooms").document(self.roomID).getDocument { (snapshot, err) in
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
                return
            }
            
            if let data = snapshot?.data() {
                let pairs = data["pairs"] as! [String:String]
                
                for key in pairs.keys {
                    if key == user.uid {
                        self.pairID = pairs[key]
                        self.groupCollectionView.reloadData()
                        self.dataComplete = true
                        break
                    }
                }
                
                wishlist = (data[self.pairID] as! [String])
                
                db.collection("users").document(self.pairID).getDocument { (snapshot, err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                        return
                    }
                    
                    if let data = snapshot?.data() {
                        let userdata = data["userdata"] as! [String:Any]
                        self.pairName = (userdata["first"] as! String) + " " + (userdata["last"] as! String)
                    } else {
                        createAlert(view: self, title: "Error", message: "Couldn't retrieve data")
                    }
                    
                }
                
            } else {
                createAlert(view: self, title: "Error", message: "Couldn't retrieve data")
            }
        }
    }
    
    // Assigns each person with their secret santa
    
    func pairPeople() {
        
        if wishlist.count == 0 {
            createAlert(view: self, title: "Error", message: "Please add items to your wishlist first")
            return
        }
        
        // Check everyone's wishlist
        var wishListPeople:[Person] = []
        
        db.collection("rooms").document(self.roomID).getDocument { (snapshot, err) in
            if let err = err {
                createAlert(view: self, title: "Error", message: err.localizedDescription)
                return
            }
            
            if let data = snapshot?.data() {
                for key in data.keys {
                    if key != "host" && key != "locked" && key != "name" && key != "date" {
                        for user in userGroup {
                            if user.getID() == key {
                                if user.getWishList().count == 0 {
                                    wishListPeople.append(user)
                                }
                            }
                        }
                    }
                }
                
                if wishListPeople.count == 0 {
                   self.participantButton.setTitle("Game Started", for: .normal)
                   self.participantButton.setTitleColor(.lightGray, for: .normal)
                   self.participantButton.isUserInteractionEnabled = false
                   self.participantButton.backgroundColor = .gray
                   
                   db.collection("rooms").document(self.roomID).updateData(["locked" : true]) { (err) in
                       if let err = err {
                           createAlert(view: self, title: "Error", message: err.localizedDescription)
                           return
                       }
                       
                       let me = Person(name: self.roomHost)
                       me.setID(newID: user.uid)
                       me.setHost(isHost: true)
                       me.setWishList(list: wishlist)
                       userGroup.append(me)
                       self.pairFunc()
                       
                   }
               } else {
                   var text = ""
                   var count = 0
                   for p in wishListPeople {
                       if count < wishListPeople.count-2 {
                           text += p.getName() + ", "
                       } else if count == wishListPeople.count-2 {
                           text += p.getName() + " and "
                       } else {
                           text += p.getName() + " "
                           text += count > 1 ? "need to add items to their wishlists, please notify them" : "needs to add items to their wishlist, please notify them"
                       }
                       count += 1
                   }
                   createAlert(view: self, title: "Error", message: text)
               }
                
            } else {
                createAlert(view: self, title: "Error", message: "Couldn't load data")
                return
            }
            
        }
        
    }
    
    func pairFunc() {
        var restart = false
        let count = userGroup.count
        var remaining = [Int]()
        
        for i in 0..<count {
            remaining.append(i)
        }
        for k in 0..<count {
            let user = userGroup[k]
            if k != count-1 {
                var rand: Int = Int(arc4random_uniform(UInt32(count)))
                while (!remaining.contains(rand) || rand == k) {
                    rand = Int(arc4random_uniform(UInt32(count)))
                }
                user.assign(person: userGroup![rand])
                remaining.removeAll(where: {$0 == rand})
                print(remaining)
            } else {
                user.assign(person: userGroup![remaining.first!])
            }
        }
        
        for person in userGroup {
            if person == person.getSecretPerson() {
                restart = true
            }
        }
        
        if restart {
            self.pairFunc()
        } else {
            for person in userGroup {

                db.collection("rooms").document(self.roomID).updateData(["pairs."+person.getID() : person.getSecretPerson()!.getID()]) { (err) in
                    if let err = err {
                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                        return
                    }
                    
                    print(person.getName() + " is assigned to " + person.getSecretPerson()!.getName())
                }
            }
            
        }
    }
    
    func updateGiftExchange() {
        if self.roomDate != nil {
            // here we set the current date

            let date = NSDate()
            let calendar = Calendar.current

            let components = calendar.dateComponents([.second, .hour, .minute, .month, .year, .day], from: date as Date)

            let currentDate = calendar.date(from: components)

            // here we set the due date. When the timer is supposed to finish
            let competitionDay = self.roomDate!

            //here we change the seconds to hours,minutes and days
            let CompetitionDayDifference = calendar.dateComponents([.day, .hour, .minute, .second], from: currentDate!, to: competitionDay)


            //finally, here we set the variable to our remaining time
            let daysLeft = CompetitionDayDifference.day
            let hoursLeft = CompetitionDayDifference.hour
            let minutesLeft = CompetitionDayDifference.minute
            let secondsLeft = CompetitionDayDifference.second
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy @ h:mm a"
            
            var daysText = " "+String(daysLeft ?? 0) + "d"
            if daysText == " 0d" {
                daysText = ""
            }
            var hoursText = " "+String(hoursLeft ?? 0) + "h"
            if hoursText == " 0h" && daysText == "" {
                hoursText = ""
            }
            var minutesText = " "+String(minutesLeft ?? 0) + "m"
            if minutesText == " 0m" && hoursText == "" {
                minutesText = ""
            }
            
            var secondsText = " "+String(secondsLeft ?? 0) + "s"
            if secondsText == " 0s" && minutesText == "" {
                secondsText = ""
            }
            
            var giftExchangeIsToday = false
            var giftExchangeIsTomorrow = false
            
            if daysText == "" {
                let todayDate = Calendar.current.dateComponents([.day], from: Date())
                let currentDay = todayDate.day!
                let setDate = Calendar.current.dateComponents([.day], from: self.roomDate!)
                let setDay = setDate.day!
                
                if currentDay == setDay {
                    giftExchangeIsToday = true
                }
                if currentDay == setDay-1 {
                    giftExchangeIsTomorrow = true
                }
            }
            
            let exchangeFormat = DateFormatter()
            exchangeFormat.dateFormat = "h:mm"
            
            if giftExchangeIsToday {
                self.giftExchangeLabel.text = "Gift Exchange Today @ "+exchangeFormat.string(from: self.roomDate!)
            } else if giftExchangeIsTomorrow {
                self.giftExchangeLabel.text = "Gift Exchange Tomorrow @ "+exchangeFormat.string(from: self.roomDate!)
            } else {
                self.giftExchangeLabel.text = "Gift Exchange: "+formatter.string(from: self.roomDate!)
            }
            
            self.giftSublabel.text = daysText+hoursText+minutesText+secondsText

        } else {
            self.giftExchangeLabel.text = ""
            self.giftSublabel.text = ""
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToWish" {
            let controller = segue.destination as! WishlistViewController
            controller.roomID = self.roomID
            controller.isEnabled = self.pairID == ""
            controller.personName = self.pairName
        } else if segue.identifier == "homeToMain" {
            let controller = (segue.destination as! UINavigationController).viewControllers[0] as! SetupViewController
            controller.fromHome = !errorDismiss
            if self.editingRoom {
                controller.editingRoom = self.editingRoom
                self.editingRoom = false
                controller.homeID = self.roomID
                controller.homeDate = self.roomDate
                controller.homeName = self.roomName
            }
        }
    }

}

class PersonCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    var user: Person!
    var id: String!
}

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}
