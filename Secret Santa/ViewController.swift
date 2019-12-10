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
        let action = UIAlertController(title: person.getName(), message: nil, preferredStyle: .actionSheet)
        
        if !locked {
            action.addAction(UIAlertAction(title: "Remove from group", style: .default, handler: { (action) in
                self.removeAction(person: person)
            }))
        }
        
        action.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (action) in
            self.reportAction(person: person)
        }))
        
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(action, animated: true, completion: nil)
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
    
    @IBOutlet weak var groupCollectionView: UICollectionView!
    
    @IBOutlet weak var participantButton: UIButton!
    
    @IBOutlet weak var wishListButton: UIButton!
    
    var isHost: Bool!
    var locked: Bool!
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
    var giftExchangeTimer: Timer!
    var timerInterval = 0.2
    var listener: ListenerRegistration!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var giftExchangeLabel: UILabel!
    @IBOutlet weak var giftSublabel: UILabel!
    
    @IBAction func menuAction(_ sender: Any) {
        
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
                self.getRoomData()
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listDownloadTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(getLists), userInfo: nil, repeats: false)
    }
    
    func setupHost() {
        print("Setup Host")
        if !locked && userGroup!.count >= 2 {
            print("1")
            participantButton.setTitleColor(.white, for: .normal)
            participantButton.setTitle("Start Game", for: .normal)
            participantButton.isUserInteractionEnabled = true
            participantButton.backgroundColor = .blue
        } else {
            if locked {
                print("2")
                participantButton.setTitle("Game Started", for: .normal)
                participantButton.setTitleColor(.lightGray, for: .normal)
                participantButton.isUserInteractionEnabled = false
                participantButton.backgroundColor = .gray
            } else {
                print("3")
                participantButton.setTitle("Invite More People", for: .normal)
            }
            participantButton.setTitleColor(.white, for: .normal)
            participantButton.isUserInteractionEnabled = true
            participantButton.backgroundColor = .red
        }
        participantButton.translatesAutoresizingMaskIntoConstraints = false
        participantButton.layer.cornerRadius = participantButton.frame.height/4
    }
    
    @IBAction func participantAction(_ sender: Any) {
        if isHost {
            if userGroup!.count >= 2 {
                self.pairPeople()
            } else {
                let shareController = UIActivityViewController(activityItems: ["Join my secret santa group! Invite Code: "+self.roomID!+"\nApp Link"], applicationActivities: [])
                self.present(shareController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if self.roomID != nil {
            checkRoom()
            setRoomDataTimer()
        }
        
        giftExchangeLabel.text = ""
        giftSublabel.text = ""
        giftExchangeTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { (timer) in
            self.updateGiftExchange()
        })
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener.remove()
    }
    
    func getRoomData() {
        var done = true
        print("GETTING ROOM DATA")
        
        if listener != nil {
            listener.remove()
        }
        listener = nil
        
        if roomID == "" {
            userGroup = []
            dataGroup = []
            performSegue(withIdentifier: "roomDisplay", sender: self)
//            let rd = RoomDisplayViewController()
//            self.present(rd, animated: true, completion: nil)
        } else {
            listener = db.collection("rooms").document(roomID).addSnapshotListener(includeMetadataChanges: true, listener: { (querySnapshot, err) in
                if let err = err {
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                    return
                }
                if done {
                    done = false
                    userGroup = []
                    dataGroup = []
                    if !querySnapshot!.metadata.hasPendingWrites {
                        if let data = querySnapshot?.data() {
                            if data.count != 0 {
                                db.collection("users").document(user.uid).getDocument { (doc, err) in
                                    if let err = err {
                                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                                        done = true
                                        return
                                    } else {
                                        if let data = doc?.data() {
                                            let userData = data["userdata"] as! [String : Any]
                                            if !(userData["rooms"] as! [String]).contains(self.roomID) && !(userData["host"] as! [String]).contains(self.roomID) {
                                                self.checkRoom()
                                                createAlert(view: self, title: "Error Loading Group", message: nil) { (complete) in
                                                    if joinRoomList.count == 0 && hostRoomList.count == 0 {
                                                        self.errorDismiss = true
                                                        self.performSegue(withIdentifier: "homeToMain", sender: self)
                                                    } else {
                                                        self.performSegue(withIdentifier: "roomDisplay", sender: self)
                                                    }
                                                    done = true
                                                    return
                                                }
                                            }
                                        } else {
                                            self.checkRoom()
                                            createAlert(view: self, title: "Error Loading Group", message: nil) { (complete) in
                                                self.performSegue(withIdentifier: "roomDisplay", sender: self)
                                                done = true
                                                return
                                            }
                                        }
                                        
                                        self.locked = (data["locked"] as! Bool)
                                        if !self.locked {
                                            self.wishListButton.isUserInteractionEnabled = true
                                            self.wishListButton.setTitleColor(.systemBlue, for: .normal)
                                        }
                                        self.isHost = (data["host"] as! String) == user.uid
                                        
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
                                                            person.setID(newID: usrUID)
                                                            userGroup.append(person)
                                                            if reloadTimer != nil {
                                                                reloadTimer.invalidate()
                                                                
                                                            }
                                                            reloadTimer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true, block: { (timer) in
                                                                reloadTimer.invalidate()
                                                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                                                                    if self.isHost {
                                                                        self.setupHost()
                                                                    }
                                                                    self.groupCollectionView.reloadData()
                                                                    done = true
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
                            if hostRoomList.count + joinRoomList.count == 0 {
                                self.errorDismiss = true
                                self.performSegue(withIdentifier: "homeToMain", sender: self)
                            } else {
                                self.performSegue(withIdentifier: "roomDisplay", sender: self)
                            }
                        }
                    }
                }
            })
        
        }

        
        // Get host
        // Get users
        // Get room name
                
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

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}
