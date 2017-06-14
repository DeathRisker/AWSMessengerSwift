//
//  ChatTableViewController.swift
//  MySampleApp
//  Copyright © 2016 Amazon. All rights reserved.
//

import UIKit
import AddressBookUI
import AWSDynamoDB
import AWSMobileHubHelper
import AWSCore
import AWSCognito

class ChatTableViewController: UITableViewController {
    
    private static var __once: () = {() -> Void in
            let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: self, action: nil)
            ChatTableViewController.navigationItem.leftBarButtonItem = loginButton
        }()
    
    let chatServices = ChatDynamoDBServices();
    
    var chatRoomDataSource:Array<ChatRoom>?
    var chatRoomName:String?
    
    
    
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    
    var reLoadChatRoomsObserver: AnyObject!
    
    var willEnterForegroundObserver: AnyObject!
    
    var isChatRoomFetching = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showChatRooms(self.refreshControl!)
        
    
        
        
        reLoadChatRoomsObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "ReLoadChatRooms"), object: nil, queue: OperationQueue.main, using: {[weak self] (note: Notification) -> Void in
            guard let strongSelf = self else { return }
            
            
             strongSelf.showChatRooms(strongSelf.refreshControl!)
            
            })
        
        
       // presentSignInViewController()
//        signInObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self] (note: NSNotification) -> Void in
//            guard let strongSelf = self else { return }
//            print("Sign In Observer observed sign in.")
//            strongSelf.setupLeftBarButtonItem()
//            // You need to call `updateTheme` here in case the sign-in happens after `- viewWillAppear:` is called.
//           
//            
//            //                        strongSelf.chatUserManager.isUserPhoneNoExist({ (isExist) in
//            //
//            //
//            //                        })
//            
//            })
//        
//        signOutObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignOutNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
//            guard let strongSelf = self else { return }
//            print("Sign Out Observer observed sign out.")
//            strongSelf.setupLeftBarButtonItem()
//          
//            })
//        
//        setupLeftBarButtonItem()
        
        
    }
    
    
    deinit {
        
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: "ReLoadChatRooms", object: nil)
      NotificationCenter.default.removeObserver(self)
        
//        NSNotificationCenter.defaultCenter().removeObserver(signInObserver)
//        NSNotificationCenter.defaultCenter().removeObserver(signOutObserver)
//        NSNotificationCenter.defaultCenter().removeObserver(willEnterForegroundObserver)
    }
    
    func setupLeftBarButtonItem() {
        struct Static {
            static var onceToken: Int = 0
        }
        
        _ = ChatTableViewController.__once
        
        if (AWSIdentityManager.defaultIdentityManager().isLoggedIn) {
            navigationItem.leftBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            navigationItem.leftBarButtonItem!.action = #selector(ChatTableViewController.handleLogout)
        }
    }
    
    func presentSignInViewController() {
        if !AWSIdentityManager.defaultIdentityManager().isLoggedIn {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let signInViewController = storyboard.instantiateViewController(withIdentifier: "SignIn") as! SignInViewController
            present(signInViewController, animated: true, completion: nil)
        }
    }
    
    
    
    
    func handleLogout() {
        if (AWSIdentityManager.defaultIdentityManager().isLoggedIn) {
            
            AWSIdentityManager.defaultIdentityManager().logout(completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
                self.navigationController!.popToRootViewController(animated: false)
                self.setupLeftBarButtonItem()
                self.presentSignInViewController()
                self.chatRoomDataSource?.removeAll()
                self.tableView.reloadData()
            } as! (Any?, Error?) -> Void)
            // print("Logout Successful: \(signInProvider.getDisplayName)");
        } else {
            assert(false)
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        
        if let _rows =  self.chatRoomDataSource {
            
            return _rows.count
        }
        
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL_ID_CHATROOM", for: indexPath) as! ChatRoomCell
        
        let chatRoom = chatRoomDataSource![indexPath.row]
    
        cell.nameLabel.text = chatRoom._name
        cell.timeLabel.text = Date().chatRoomFormatted(chatRoom._createdAt!)
        

        
        return cell
    }
    
    
  
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ConversationViewController"  {
            
            if let _conversation = segue.destination as? ConversationViewController {
                
                let indexPath = tableView.indexPathForSelectedRow
                
                _conversation.selectedChatRoom = chatRoomDataSource![(indexPath?.row)!]
                
            }
            
        }
        
        
    }
    
    
    // MARK: - User Actions
    
    @IBAction func showChatRooms(_ sender: UIRefreshControl) {
        
        if AWSIdentityManager.defaultIdentityManager().isLoggedIn == false || isChatRoomFetching {
            
            return
        }
        
        isChatRoomFetching = true
        self.refreshControl?.beginRefreshing()
        
        chatServices.loadUserChatRooms().continue { (task) -> AnyObject? in
            
            
            
            DispatchQueue.main.async(execute: {
                
                if let _chatRooms = task.result as? Array<ChatRoom> {
                    
                    self.chatRoomDataSource?.removeAll()
                    
                    self.chatRoomDataSource = _chatRooms
                    
                    //Sort loaded chat rooms by creation date
                    self.chatRoomDataSource?.sort(by: { (item1, item2) -> Bool in
                        
                        let date1 = Date().formattedISO8601Date(item1._createdAt!)
                        let date2 = Date().formattedISO8601Date(item2._createdAt!)
                        return date1.compare(date2) == .orderedDescending
                    })
                    
                }
                
                self.isChatRoomFetching = false
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                
            })
            
            return nil
        }
        
    }
    
    
    
}


class ChatRoomCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}

