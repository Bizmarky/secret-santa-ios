//
//  SetupViewController.swift
//  Secret Santa
//
//  Created by Marcus McCallum on 11/28/19.
//  Copyright © 2019 bizmarky. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FSCalendar

class SetupViewController: UIViewController, UITextFieldDelegate, FSCalendarDelegate, FSCalendarDataSource, UIDocumentPickerDelegate {
    
    var host: Bool!
    var join: Bool!
    var titleText: UILabel!
    var roomID: String!
    var roomName: String!
    var roomDate: Date!
    var fromHome = false
    var code: String!
    var chosenDate: Date!
    var homeID: String!
    var homeName: String!
    var homeDate: Date!
    var editingRoom: Bool!
    
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    
    @IBOutlet weak var groupNameField: UITextField!
    
    @IBOutlet weak var groupIDField: UITextField!
    
    @IBOutlet weak var dateField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var logoutButton: UIButton!
    
    // -156 to -86
    @IBOutlet weak var submitConstraint: NSLayoutConstraint!
    
    // 66 to 0
    @IBOutlet weak var groupIDConstraint: NSLayoutConstraint!
    
    // 66 to 0
    @IBOutlet weak var dateConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var calendarView: FSCalendar!
    
    @IBOutlet weak var overlay: UIView!
    
    // 24 to 620
    @IBOutlet weak var dateViewConstraintTop: NSLayoutConstraint!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var dateView: UIView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBAction func logoutAction(_ sender: Any) {
        if fromHome {
            dismiss(animated: true, completion: nil)
        } else {
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
        }
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        updateDate()
           
       }
    
    @IBAction func dateDoneAction(_ sender: Any) {
        
        hideCalendar()
        
    }
    
    func updateDate() {
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: datePicker.date)
        let hour = timeComponents.hour!
        let minute = timeComponents.minute!
        
        let dayComponents = Calendar.current.dateComponents([.day, .month, .year], from: calendarView.selectedDate!)
        let day = dayComponents.day!
        let month = dayComponents.month!
        let year = dayComponents.year!
        
        var finalComponents = DateComponents()
        finalComponents.day = day
        finalComponents.month = month
        finalComponents.year = year
        finalComponents.hour = hour
        finalComponents.minute = minute
        
        let calender = Calendar.current
        chosenDate = calender.date(from: finalComponents)
        calendarView.select(chosenDate)
        datePicker.setDate(chosenDate, animated: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        dateField.text = formatter.string(from: chosenDate)
        formatter.dateFormat = "MMM d, yyyy"
        dateLabel.text = formatter.string(from: chosenDate)
        formatter.dateFormat = "h:mm a"
        timeLabel.text = formatter.string(from: chosenDate)
        
    }
    
    @IBAction func datePickerAction(_ sender: Any) {
        updateDate()
    }
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        return Date().ceil(precision: 5*60)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if editingRoom == nil {
            editingRoom = false
        }
        
        dateView.backgroundColor = .white
        dateLabel.textColor = .black
        timeLabel.textColor = .black
        datePicker.tintColor = .black
        datePicker.backgroundColor = .clear
        calendarView.backgroundColor = .white
        chosenDate = editingRoom ? homeDate.ceil(precision: 5*60) : Date().ceil(precision: 5*60)
        datePicker.minimumDate = Date().ceil(precision: 5*60)
        datePicker.minuteInterval = 5
        datePicker.setDate(chosenDate, animated: false)
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.select(chosenDate)
        let formatter = DateFormatter()
        if editingRoom {
            formatter.dateFormat = "MMM d, yyyy h:mm a"
            dateField.text = formatter.string(from: chosenDate)
            
            submitButton.setTitle("Save", for: .normal)
        }
        formatter.dateFormat = "MMM d, yyyy"
        dateLabel.text = formatter.string(from: chosenDate)
        formatter.dateFormat = "h:mm a"
        timeLabel.text = formatter.string(from: chosenDate)
        
        self.dateViewConstraintTop.constant = 620
        self.dateView.layer.cornerRadius = 12
        overlay.alpha = 0
        overlay.isHidden = true
        
        self.setupToHideKeyboardOnTapOnView()
        
        groupNameField.delegate = self
        groupIDField.delegate = self
        dateField.delegate = self
        
        groupNameField.text = homeName == nil ? groupNameField.text! : homeName
        groupIDField.placeholder = homeID == nil ? "Invite Code: " : "Invite Code: "+homeID
                
        setLogoutButton()
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.layer.cornerRadius = submitButton.frame.height/4
        
        titleText = UILabel(frame: CGRect(origin: self.view.center, size: CGSize(width: self.view.frame.width, height: 18)))
        titleText.translatesAutoresizingMaskIntoConstraints = false
        
        titleText.font = .systemFont(ofSize: 16, weight: .semibold)
        self.navigationItem.titleView = titleText
        self.navigationItem.setHidesBackButton(true, animated: true)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        userTypeAction(self)
        
        userTypeControl.isHidden = editingRoom
        
        if !editingRoom {
            userGroup = []
            dataGroup = []
            
            hostRoomList = []
            joinRoomList = []
            roomNameMap = [:]
            
            hideAll()
            checkRoom()
                    
            code = ""
        }
        
        let tap2 = UITapGestureRecognizer()
        tap2.addTarget(self, action: #selector(hideCalendar))
        tap2.numberOfTouchesRequired = 1
        tap2.numberOfTapsRequired = 1
        overlay.addGestureRecognizer(tap2)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(groupNameField) {
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            return newLength < 14
        } else {
            return true
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if !editingRoom {
            if textField.isEqual(groupNameField) {
                // max characters 22
                let codeText = groupNameField.text!
                code = codeText.replacingOccurrences(of: " ", with: "-").lowercased()
                self.groupIDField.placeholder = "Invite Code: " + code
            } else if textField.isEqual(groupIDField) && textField.text != "" {
                textField.text = textField.text?.replacingOccurrences(of: " ", with: "-").lowercased()
            }
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.isEqual(dateField) {
            textField.resignFirstResponder()
            showCalendar()
            return false
        }
        return true
    }
    
    func showCalendar() {
        self.view.endEditing(true)
        overlay.isHidden = false
        self.dateViewConstraintTop.constant = 24
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.overlay.alpha = 0.5
        }
    }
    
    @objc func hideCalendar() {
        self.dateViewConstraintTop.constant = 620
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
            self.overlay.alpha = 0
        }) { (complete) in
            self.overlay.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !editingRoom {
            if host {
                if textField.isEqual(groupNameField) {
                    textField.resignFirstResponder()
                    self.showCalendar()
                    return false
                }
            } else if join {
                buttonAction(self)
            }
        } else {
            self.view.endEditing(true)
        }
        return true
    }
    
    func setLogoutButton() {
        if fromHome {
            logoutButton.setTitle("Cancel", for: .normal)
        }
    }
    
    func hideAll() {
        logoutButton.alpha = 0
        userTypeControl.alpha = 0
        groupIDField.alpha = 0
        submitButton.alpha = 0
        titleText.alpha = 0
        groupNameField.alpha = 0
        dateField.alpha = 0
    }
    
    func showAll() {
        UIView.animate(withDuration: 0.2) {
            self.logoutButton.alpha = 1
            self.userTypeControl.alpha = 1
            self.groupIDField.alpha = 1
            self.submitButton.alpha = 1
            self.titleText.alpha = 1
            self.groupNameField.alpha = 1
            self.dateField.alpha = 1
        }
    }
    
    func checkRoom() {
        db.collection("users").document(user.uid).getDocument { (document, err) in
            if let err = err {
                print(err)
                self.showAll()
                self.activityIndicatorView.isHidden = true
            } else {
                let data = document?.data()?.values.first as! [String:Any]
                
                let dataRooms = data["rooms"] as! [String]
                let hostRooms = data["host"] as! [String]
                
                if userData == nil {
                    userData = [:]
                }
                
                userData["first"] = (data["first"] as! String)
                userData["last"] = (data["last"] as! String)
                userData["email"] = (data["email"] as! String)
                
                if dataRooms.isEmpty && hostRooms.isEmpty {
                    self.showAll()
                    self.activityIndicatorView.isHidden = true
                } else {
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
                    if !self.fromHome {
                        self.prepareRoom()
                    } else {
                        self.showAll()
                        self.activityIndicatorView.isHidden = true
                    }
                }
            }
        }
    }
    
    func prepareRoom() {
        self.roomID = ""
        
        if defaults.object(forKey: "currentRoom") != nil {
            self.roomID = defaults.string(forKey: "currentRoom")
        } else if !hostRoomList.isEmpty {
            if hostRoomList.count == 1 {
                self.roomID = hostRoomList[0]
            }
        } else if !joinRoomList.isEmpty {
            if joinRoomList.count == 1 {
                self.roomID = joinRoomList[0]
            }
        }
        
        self.performSegue(withIdentifier: "mainToHome", sender: self)
    }
    
    @IBAction func userTypeAction(_ sender: Any) {
        if !editingRoom {
            if self.userTypeControl.selectedSegmentIndex == 0 {
                self.setupHost()
            } else if self.userTypeControl.selectedSegmentIndex == 1 {
                self.setupJoin()
            }
        } else {
            titleText.text = "Edit Group"
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        activityIndicatorView.isHidden = false
        
        if editingRoom {
            self.view.endEditing(true)
            if groupNameField.text == "" && dateField.text == "" {
                activityIndicatorView.isHidden = true
                createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
                return
            }
            db.collection("rooms").document(homeID).updateData(["name" : self.groupNameField.text!, "date" : self.chosenDate.timeIntervalSince1970]) { (err) in
                if let err = err {
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                    return
                }
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        
        if !checkTextFields() {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "Text fields cannot be blank")
            return
        }
        
        if joinRoomList.contains(code) || hostRoomList.contains(code) {
            activityIndicatorView.isHidden = true
            createAlert(view: self, title: "Error", message: "You are already in the group \""+self.code+"\"")
            return
        }
        
        self.view.endEditing(true)

        if host {
            
            // Firebase check room id
            // Firebase create room id
            // Firebase join room with uid as key and wishlist as children
            
            db.collection("rooms").document(code).getDocument(completion: { (querySnapshot, err) in
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if !querySnapshot!.exists {
                        db.collection("rooms").document(self.code).setData([user.uid:[], "locked":false, "host":user.uid, "name":self.groupNameField.text!, "date":self.chosenDate.timeIntervalSince1970]) { err in
                            if let err = err {
                                self.activityIndicatorView.isHidden = true
                                createAlert(view: self, title: "Error", message: err.localizedDescription)
                            } else {
                                db.collection("users").document(user.uid).updateData(["userdata.host" : FieldValue.arrayUnion([self.code!])], completion: { (err) in
                                    if let err = err {
                                        self.activityIndicatorView.isHidden = true
                                        createAlert(view: self, title: "Error", message: err.localizedDescription)
                                    } else {
                                        // Segue to home
                                        self.roomID = self.code!
                                        self.roomName = self.groupNameField.text!
                                        self.roomDate = self.chosenDate
                                        self.performSegue(withIdentifier: "mainToHome", sender: self)
                                    }
                                })
                            }
                        }
                    }
                    if let data = querySnapshot?.data() {
                        if data.count != 0 {
                            self.activityIndicatorView.isHidden = true
                            createAlert(view: self, title: "Group already exists", message: "Please choose a new Group ID")
                        }
                    }
                }
            })
            
        } else if join {
            
            // Firebase check if room exists
            // Firebase download people data
            var eventName = ""
            var eventDate: Date!
            db.collection("rooms").document(self.groupIDField.text!.lowercased()).getDocument(completion: { (querySnapshot, err) in
                if let err = err {
                    self.activityIndicatorView.isHidden = true
                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                } else {
                    if let data = querySnapshot?.data() {
                        if data.count != 0 {
                            for key in data.keys {
                                if key != "locked" && key != user.uid {
                                    let usrUID = key
                                    if usrUID != "host" && usrUID != "name" && usrUID != "date" {
                                        let usrList = data[key] as! [String]
                                        dataGroup.append([usrUID:usrList])
                                    }
                                }
                            }
                            
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
                                    eventName = usr[usrUID] as! String
                                } else if usrUID == "date" {
                                    date = true
                                    eventDate = Date(timeIntervalSince1970: usr[usrUID] as! TimeInterval)
                                }
                                
                                db.collection("users").document(usrUID).getDocument { (document, err) in
                                    
                                    if let err = err {
                                        print(err)
                                    } else  if let _ = document, document!.exists {
                                        if !name && !date {
                                            let rawdata = document!.data()!
                                            let data = rawdata["userdata"] as! [String:Any]
                                            let personName = (data["first"] as! String) + " " + (data["last"] as! String)
                                            
                                            if !host {
                                                let personWishlist = usr[usrUID] as! [String]
                                                let person = Person(name: personName)
                                                person.setWishList(list: personWishlist)
                                                userGroup.append(person)
                                            }
                                        }

                                    } else {
                                        print(usrUID+" does not exist")
                                    }
                                }
                            }
                            
                            self.roomName = eventName
                            self.roomDate = eventDate
                            db.collection("rooms").document(self.groupIDField.text!.lowercased()).updateData([user.uid:[]]) { err in
                                if let err = err {
                                    self.activityIndicatorView.isHidden = true
                                    createAlert(view: self, title: "Error", message: err.localizedDescription)
                                } else {
                                    db.collection("users").document(user.uid).updateData(["userdata.rooms" : FieldValue.arrayUnion([self.groupIDField.text!.lowercased()])]) { (err) in
                                        if let err = err {
                                            self.activityIndicatorView.isHidden = true
                                            createAlert(view: self, title: "Error", message: err.localizedDescription)
                                        } else {
                                            // Segue to home
                                            self.roomID = self.groupIDField.text!.lowercased()
                                            self.performSegue(withIdentifier: "mainToHome", sender: self)
                                        }
                                    }
                                }
                            }
                        } else {
                            self.activityIndicatorView.isHidden = true
                            createAlert(view: self, title: "Group does not exist", message: "Please check Group ID")
                        }
                    } else {
                        self.activityIndicatorView.isHidden = true
                        createAlert(view: self, title: "Group does not exist", message: "Please check Group ID")
                    }
                }
            })
            
        }
    }
    
    func setupHost() {
        let codeText = groupNameField.text!
        code = codeText.replacingOccurrences(of: " ", with: "-")
        self.groupIDField.text = ""
        self.groupIDField.placeholder = "Invite Code: " + code
        self.groupIDConstraint.constant = 58
        self.dateConstraint.constant = 58
        self.submitConstraint.constant = -164
        UIView.animate(withDuration: 0.3, animations: {
            self.groupNameField.alpha = 1
            self.dateField.alpha = 1
            self.view.layoutIfNeeded()
        })
        self.titleText.text = "Host"
        self.submitButton.setTitle("Create", for: .normal)
        host = true
        join = false
        userTypeControl.tintColor = UIColor.blue
        userTypeControl.selectedSegmentTintColor = UIColor.blue
        submitButton.backgroundColor = .blue
        groupIDField.isUserInteractionEnabled = false
    }
    
    func setupJoin() {
        self.groupIDField.text = ""
        self.groupIDField.placeholder = "Enter Invite Code"
        self.groupIDConstraint.constant = 0
        self.dateConstraint.constant = 0
        self.submitConstraint.constant = -94
        UIView.animate(withDuration: 0.3, animations: {
            self.groupNameField.alpha = 0
            self.dateField.alpha = 0
            self.view.layoutIfNeeded()
        })
        self.titleText.text = "Join"
        host = false
        join = true
        userTypeControl.tintColor = UIColor.red
        userTypeControl.selectedSegmentTintColor = UIColor.red
        submitButton.backgroundColor = .red
        self.submitButton.setTitle("Join", for: .normal)
        groupIDField.isUserInteractionEnabled = true
    }
    
    func checkTextFields() -> Bool {
        if host {
            return groupNameField.text != "" && dateField.text != ""
        } else {
            return groupIDField.text != ""
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainToHome" {
            let controller = (segue.destination as! UINavigationController).viewControllers[0] as! ViewController
            controller.roomID = self.roomID
            controller.roomName = self.roomName
            controller.roomDate = self.roomDate
//            controller.setRoomDataTimer()
//            controller.checkRoom()
        }
    }
    
}

func createAlert(view: UIViewController, title: String?, message: String?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(action)
    view.present(alert, animated: true, completion: nil)
}

func createAlert(view: UIViewController, title: String?, message: String?, completion: @escaping (Bool) -> ()) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .default) { (action) in
        completion(true)
    }
    alert.addAction(action)
    view.present(alert, animated: true, completion: nil)
}

extension UIViewController
{
    func setupToHideKeyboardOnTapOnView()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))

        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}

extension Date {

    public func round(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .toNearestOrAwayFromZero)
    }

    public func ceil(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .up)
    }

    public func floor(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .down)
    }

    private func round(precision: TimeInterval, rule: FloatingPointRoundingRule) -> Date {
        let seconds = (self.timeIntervalSinceReferenceDate / precision).rounded(rule) *  precision;
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}
