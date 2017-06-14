//
//  CreateChatRoomVC.swift
//  MySampleApp
//  Copyright © 2016 Amazon. All rights reserved.
//

import UIKit
import ContactsUI


class CreateChatRoomVC: UITableViewController,CNContactPickerDelegate {
    
    @IBOutlet weak var toAddRecipeintsPressLabel: UILabel!
    
    
    @IBOutlet weak var chatRoomNameTextField: UITextField!
    
    
    let userServices = UserDynamoDBServices();
    let chatServices = ChatDynamoDBServices();
    
    var userDataSource = Array<UserProfile>()
    
    let activityIndicator = UIActivityIndicatorView()
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        toAddRecipeintsPressLabel.isHidden = userDataSource.count != 0
        
        return userDataSource.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL_ID_USER", for: indexPath)
        
        let user = userDataSource[indexPath.row]
        
        cell.textLabel?.text = user._name
        
        
        return cell
    }
    
    
    
    // MARK: General
    
    
//    func getAllSelectedPhone() -> Array<String> {
//        
//        var phoneNumbers = Array<String>()
//        
//        
//        for contact in recipeintsDataSource {
//            
//            
//            let number  = getMobileNumberWith(contact)!
//            
//            phoneNumbers.append(number)
//            
//            
//        }
//        return phoneNumbers
//        
//        
//    }
//    
    
    
    func getMobileNumberWith(_ person:CNContact) -> String? {
    
        
        for num in person.phoneNumbers {
            
            let numVal = num.value 
            
            if num.label == CNLabelPhoneNumberMobile {
                
                let regex = try! NSRegularExpression(pattern: "[^0-9\\+]", options: [])
                
                return regex.stringByReplacingMatches(
                    in: numVal.stringValue,
                    options: [],
                    range: NSRange(location: 0, length: numVal.stringValue.characters.count),
                    withTemplate: ""
                )

                
            }
        }
        
        
        
        
        

        
        return nil
        
    }
    
    // MARK: - UI Actions
    
    @IBAction func showContacts(_ sender: UIBarButtonItem) {
        
        
        let peoplePicker = CNContactPickerViewController()
        peoplePicker.delegate = self
        let arrKeys = [CNContactPhoneNumbersKey];
        peoplePicker.displayedPropertyKeys = arrKeys;
        self.present(peoplePicker, animated: true, completion: nil)
        
    }
    
    
    func showBusyIndicator(_ isShow:Bool) {
        
        
        if isShow {
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            activityIndicator.startAnimationOnTop()
            
        }else{
            
            activityIndicator.stopAnimationOnTop()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
                
    }
    
    
    func isUserRegistered(_ mobileNumber: String,contact: CNContact) {
        
        
        // output: "This+is+my+string"
       
            
            
            showBusyIndicator(true)
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        let date = formatter.string(from: Date())
        print("Send Reqeust to validate phone number At: \(date)")
        
        
            userServices.getUserFromPhoneNo(mobileNumber).continueWith{ (task) -> AnyObject? in
                
                self.showBusyIndicator(false)
                
                
                if let _userProfile = task.result as? UserProfile {
                    
                    
                    print(_userProfile)
        
                    
                    _userProfile._name = contact.givenName + " " + contact.familyName
                    
                    DispatchQueue.main.async(execute: {
                        
                        let date = formatter.string(from: Date())
                        print("Recieve verification response At: \(date)")
                        self.userDataSource.append(_userProfile)
                        self.tableView.reloadData()
                        
                    })
                    
                    
                }else{
                    
                    
                    UIAlertController.showErrorAlertWithMessage("This phone number is not registered")
                    
                    
                }
                
                return nil
            }
            
        
        
        
        
    }
    
    @IBAction func createChatRoom(_ sender: UIButton) {
        
        
        if userDataSource.count > 0 {
            
            showBusyIndicator(true)
            
            let name = chatRoomNameTextField.text?.isEmpty == true ? nil : chatRoomNameTextField.text
            
            chatServices.saveNewChatRoom(name,userProfiles: userDataSource).continueWith{ (task) -> AnyObject? in
                
                
                if let result = task.result as? String {
                    
                    print(result)
                    
                    DispatchQueue.main.async(execute: {
                        self.navigationController?.popViewController(animated: true)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "ReLoadChatRooms"), object: nil)
                    })
                    
                }
                self.showBusyIndicator(false)
                return nil
                
            }
            
        }
        else {
            
            UIAlertController.showErrorAlertWithMessage("Please Add at least one recipient user")
            
            
        }
    }
    
    
    
    
    // MARK: - CNContactPickerDelegate
    
    
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        let date = formatter.string(from: Date())

        print("contact is selected At: \(date)")
        
        self.dismiss(animated: true,completion: {
            
            let first = contact.givenName
            let last  = contact.familyName
            
            let isEmptyNames = !first.isEmpty || !last.isEmpty
            
            if let mobileNumber = self.getMobileNumberWith(contact), isEmptyNames {
                
                self.isUserRegistered(mobileNumber,contact: contact)
                
                
            }else{
                
                UIAlertController.showErrorAlertWithMessage("First or last name and mobile number is missing from selected contact, please select valid contact")
                
            }
            
            self.tableView.reloadData()
        })
    }
    
    
}

