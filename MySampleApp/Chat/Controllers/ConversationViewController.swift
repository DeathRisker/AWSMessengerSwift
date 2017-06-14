//
//  ConversationViewController.swift
//  MySampleApp
//  Copyright © 2016 Amazon. All rights reserved.
//

import UIKit
import AWSMobileHubHelper


import WebKit
import MediaPlayer
import MobileCoreServices
import AWSSNS


func regionType(_ region:String) -> AWSRegionType {
    
    
    
    switch region {
        
    case "us-east-1": return .USEast1
    case "us-west-1": return .USWest1
    case "us-west-2": return .USWest2
    case "eu-west-1": return .EUWest1
    case "us-central-1": return .EUCentral1
    case "ap-southeast-1": return .APSoutheast1
    case "ap-southeast-2": return .APSoutheast2
    case "ap-northeast-1": return .APNortheast1
    case "sa-east-1": return .SAEast1
    case "cn-north-1": return .CNNorth1
        
    default: return .Unknown
    }
    
}



class ConversationViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendView: UIView!
    
    @IBOutlet weak var sendViewBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendTextField: UITextField!
    
    
    @IBOutlet  var imagePickBarItem: UIBarButtonItem!
    
    @IBOutlet var imageUploadingBarItem: UIBarButtonItem!
    
    var uploadActivityIndicatorView:UIActivityIndicatorView?
    
    
    var conversationDataSource:Array<Conversation> = Array()
    
    var recipientUsers:Array<UserProfile>!
    
    
    var selectedChatRoom:ChatRoom?
    
    var localCache:LocalImageCache!
    
    let  chatServices = ChatDynamoDBServices()
    let  userServices = UserDynamoDBServices()
    
    var imageDonwloadingAtRows = Array<Int>()
    
    
    //var task: NSURLSessionDownloadTask = NSURLSessionDownloadTask()
    let session: URLSession = URLSession.shared
    
    
    fileprivate let userFileManager = AWSUserFileManager.defaultUserFileManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localCache = LocalImageCache(_subDirectoryName: selectedChatRoom!._chatRoomId!)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 112.0; // set
        
        self.title = selectedChatRoom?._name
        
        // Keyboard stuff.
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(ConversationViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        center.addObserver(self, selector: #selector(ConversationViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
        
        //self.loadConversation()
        self.loadRecipientsAndConversations(true)
        showUploadingStatusView(false)
    }
    
    
    func showUploadingStatusView(_ isShow:Bool) {
        
        if isShow {
            
            self.navigationItem.rightBarButtonItem = imageUploadingBarItem
        }else{
            self.navigationItem.rightBarButtonItem = imagePickBarItem
        }
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let info:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        
        let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
        
        
        UIView.animate(withDuration: 0.25, delay: 0.25, options: UIViewAnimationOptions(), animations: {
            self.sendViewBottomLayoutConstraint.constant = keyboardHeight
            }, completion: nil)
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        //let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        
        //let keyboardHeight: CGFloat = keyboardSize.height
        
        let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
        
        UIView.animate(withDuration: 0.25, delay: 0.25, options: UIViewAnimationOptions(), animations: {
            self.sendViewBottomLayoutConstraint.constant = 0
            }, completion: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    // MARK: - Actions
    
    @IBAction func sendImage(_ sender: UIBarButtonItem) {
        
        
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
        
        
    }
    
    @IBAction func sendMessage(_ sender: AnyObject) {
        
        if self.sendTextField.text?.isEmpty == true {
            return
        }
        
        
        let conversation = self.createConversation()
        
        self.conversationDataSource.append(conversation!)
        
        
        self.updateUIAfterMessageSent()
        
        self.sendMessageToServer(conversation!)
        
    }
    
    func updateUIAfterMessageSent() {
        
        //        self.tableView.reloadData()
        //
        
        
        let IndexPathOfLastRow = IndexPath(row: self.conversationDataSource.count - 1, section: 0)
        self.tableView.insertRows(at: [IndexPathOfLastRow], with: UITableViewRowAnimation.none)
        
        
        
        self.tableView.scrollToRow(at: IndexPath(row: self.conversationDataSource.count-1, section:0), at: .bottom, animated: true)
        
        
        self.sendTextField.text = ""
        
    }
    
    func createConversation() -> Conversation! {
        
        let conversation = Conversation()
        
        let createdAt = Date().formattedISO8601
        conversation?._message = sendTextField.text
        conversation?._createdAt = createdAt
        conversation?._userId = AWSIdentityManager.default().identityId
        conversation?._chatRoomId = selectedChatRoom?._chatRoomId
        conversation?._conversationId = UUID().uuidString
        return conversation
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        print("deinit called")
    }
    
    // MARK: - API Calls
    
    func loadRecipientsAndConversations(_ isShowLoader:Bool) {
        
        var activityIndicator:UIActivityIndicatorView?
        
        if isShowLoader {
            
            activityIndicator = UIActivityIndicatorView()
            
            activityIndicator?.startAnimationOnTop()
        }
        
        userServices.loadUsersWithChatRoom(selectedChatRoom!).continueWith { (task) -> AnyObject? in
            
            if let users = task.result as? Array<UserProfile> {
                
                
                self.recipientUsers = users
                
                return self.chatServices.loadConversation((self.selectedChatRoom?._chatRoomId)!)
            }
            
            return nil
            }.continueWith { (task) -> AnyObject? in
                
                if let _conversations = task.result as? Array<Conversation> {
                    
                    self.conversationDataSource.removeAll()
                    self.conversationDataSource = _conversations
                    
                    
                    
                    DispatchQueue.main.async(execute: {
                        
                        self.tableView.reloadData()
                        self.tableViewScrollToBottom(true)
                        
                    })
                    
                    
                    
                }
                
                activityIndicator?.stopAnimationOnTop()
                
                return nil
                
        }
        
    }
    
    func tableViewScrollToBottom(_ animated: Bool) {
        
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            
            let numberOfSections = self.tableView.numberOfSections
            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections-1)
            
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows-1, section: (numberOfSections-1))
                self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: animated)
            }
            
        })
    }
    
    func sendMessageToServer(_ conversation:Conversation) {
        
        
        
        chatServices.sendMessage(conversation).continueWith { (task) -> AnyObject? in
            
            if let _result = task.result {
                
                self.sendPush(conversation)
                print(_result)
            }
            
            return nil
            
        }
        
        
        
        
    }
    
    
    func sendPush(_ conversation:Conversation) {
        
        //"us-east-1:bdad4021-75b8-44c1-a079-3b6e9e565b47"
        let poolID = Bundle.getPoolId()
        
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:regionType(Bundle.getRegionFromCreadentialProvider()),
                                                                identityPoolId:poolID)
        
        let configuration = AWSServiceConfiguration(region:regionType(Bundle.getRegionFromPushManager()), credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        for userProfile in recipientUsers {
            
            //skip to current user
            if userProfile._userId == AWSIdentityManager.default().identityId {
                
                continue
            }
            
            if let targetArns = userProfile._pushTargetArn {
                
                
                for deviceTargetArn in targetArns {
                    
                    do {
                        
                        let sns = AWSSNS.default()
                        let request = AWSSNSPublishInput()
                        request?.messageStructure = "json"
                        
                        
                        let senderName = AWSIdentityManager.default().identityProfile?.userName
                        
                        //let defaultMessageFormat = "Message sent by \(senderName!)"
                        //let dataFormat = "\"chatRoomId\":\"\(conversation._chatRoomId!)\""
                        
                        let devicePayLoad = ["default": "Message sent by \(senderName!)", "APNS_SANDBOX": "{\"aps\":{\"alert\": \"Message sent by \(senderName!)\",\"sound\":\"default\", \"badge\":\"1\"}, \"chatRoomId\":\"\(conversation._chatRoomId!)\" }","APNS": "{\"aps\":{\"alert\": \"Message sent by \(senderName!)\"}, \"chatRoomId\":\"\(conversation._chatRoomId!)\" }","GCM":"{\"data\":{\"message\":\"Message sent by \(senderName!)\", \"chatRoomId\":\"\(conversation._chatRoomId!)\"}}"]
                        
                        
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: devicePayLoad, options: JSONSerialization.WritingOptions.init(rawValue: 0))
                        
                        
                        
                        
                        request?.subject = "Message Sent By \(senderName)"
                        request?.message = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String
                        
                        request?.targetArn = deviceTargetArn
                        
                        
                        sns.publish(request!).continueWith { (task) -> AnyObject! in
                            print("error \(task.error), result:; \(task.result)")
                            return nil
                        }
                        
                        
                    } catch let parseError {
                        print(parseError)                                                          // Log the error thrown by `JSONObjectWithData`
                    }
                    
                }
                
            }
            
            
        }
        
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.conversationDataSource.count
    }
    
    
    //     func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    //
    //
    //        return tableView.dequeueReusableCellWithIdentifier("CELL_ID_SEND")
    //    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        //CELL_ID_OTHER
        //CELL_ID_ME
        
        
        let conversation = conversationDataSource[indexPath.row]
        
        
        if let _imageName = conversation._imageUrlPath {
            
            
            var identifier = ""
            var userName = "Me"
            
            if isLoggedInUserMessage(conversation._userId!) {
                
                identifier = "CELL_ID_IMG_ME"
            
            }else {
                
                userName = self.userNameFromConversation(conversation)
                identifier = "CELL_ID_IMG_OTHER"
            }
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            
            let namelabel = cell.viewWithTag(2) as! UILabel
            let timeLabel = cell.viewWithTag(4) as! UILabel
            
            
            
            timeLabel.text = Date().conversationTimeFormatted(conversation._createdAt!)
            namelabel.text = userName
            
            
            
            if let image = localCache.loadImageWith(_imageName) {
                
                // 2
                // Use cache
                print("Cached image used, no need to download it")
                
                let imageView = cell.viewWithTag(1) as! UIImageView
                imageView.image = image
                
            }else{
                
                let imageView = cell.viewWithTag(1) as! UIImageView
                imageView.image = nil
                
                
                let url:URL! =  URL(string: _imageName)
                
                if self.imageDonwloadingAtRows.contains(indexPath.row) == false {
                    
                    print("\(indexPath.row) + image downloading started")
                    self.imageDonwloadingAtRows.append(indexPath.row)
                    
                    let task = self.session.downloadTask(
                        with: url,
                        completionHandler: {[weak self] (
                            location:URL?,
                            reponse:URLResponse?,
                            error:Error?) in
                            guard let strongSelf = self else {return}
                            
                            if let data = try? Data(contentsOf: url), data.count > 0 {
                                
                                DispatchQueue.main.async(execute: {
                                    
                                    let img:UIImage! = UIImage(data: data)
                                    // Before we assign the image, check whether the current cell is visible
                                    if let updateCell = tableView.cellForRow(at: indexPath) {
                                        
                                        let imageView = updateCell.viewWithTag(1) as! UIImageView
                                        imageView.image = img
                                        tableView.reloadData()
                                        
                                    }
                                    
                                    strongSelf.imageDonwloadingAtRows.remove(at: strongSelf.imageDonwloadingAtRows.index(of: indexPath.row)!)
                                    
                                    strongSelf.localCache.saveImage(img, name: _imageName)
                                    
                                })
                                
                            }
                            
                        })
                    task.resume()
                    
                    
                    
                }else {
                    
                    print("This image is being uploaded.")
                }
                
                
                
            }
            
            
            
            ////////////
            
            //namelabel.text = "Sent by " + self.userNameFromConversation(conversation)
            
            return cell
        }
        
        let identifier = isLoggedInUserMessage(conversation._userId!) ? "CELL_ID_ME" : "CELL_ID_OTHER"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        
        
        
        let messageLabel = cell.viewWithTag(1) as! UILabel
        
        let timeLabel = cell.viewWithTag(4) as! UILabel
        
        messageLabel.text = conversation._message
        timeLabel.text = Date().conversationTimeFormatted(conversation._createdAt!)
        
        
        if isLoggedInUserMessage(conversation._userId!) == false {
            
            let namelabel = cell.viewWithTag(2) as! UILabel
            
            namelabel.text = self.userNameFromConversation(conversation)
            
        }
        
        
        cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.width/2.0, 0, cell.bounds.width/2.0)
        
        return cell
    }
    
    
    func userNameFromConversation(_ conversation:Conversation) -> String {
        
        for user in recipientUsers {
            
            if user._userId == conversation._userId {
                
                if let name  = user._name {
                    return name
                }
    
            }
            
        }
        
        return "Unknown Name"
    }
    
    func isLoggedInUserMessage(_ userID:String) -> Bool {
        
        if userID == AWSIdentityManager.default().identityId {
            return true
        }
        
        return false
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    fileprivate func uploadLocalContent(_ localContent: AWSLocalContent , conversation:Conversation) {
        
        showUploadingStatusView(true)
        
        localContent.uploadWithPin(onCompletion: false, progressBlock: {(content: AWSLocalContent?, progress: Progress?) -> Void in
            // You can get uploading progress here ..
            }, completionHandler: {[weak self](content: AWSContent?, error: Error?) -> Void in
                guard let strongSelf = self else { return }
                strongSelf.showUploadingStatusView(false)
                if let error = error {
                    print("Failed to upload an object. \(error)")
                } else {
                    content?.getRemoteFileURL(completionHandler: { (url, error) in
                        
                        // get full path of uploaded image
                        let imagePath = url?.absoluteString.components(separatedBy: "?").first
                        
                        // store into conversation object
                        conversation._imageUrlPath = imagePath
                        
                        print(url?.absoluteString)
                        
                        // send conversaiton object to Conversation Table
                        strongSelf.sendMessageToServer(conversation)
                        
                    })
                    
                }
            })
    }
    
    
    
    fileprivate func uploadWithData(_ data: Data) {
        
        // convert current date into string
        let createdAt = NSString(format:"%@",Date() as CVarArg) as String
        
        //set image name with current date
        var imageName = "\(createdAt).png"
        
        //set upload desitnation folder in key
        let key = "private/\(AWSIdentityManager.default().identityId!)/\(imageName)"
        
        // create & initialize Conversation object
        
        let characters = (CharacterSet.urlHostAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        
        characters.removeCharacters(in: "+:")
        
        
        imageName = imageName.addingPercentEncoding(withAllowedCharacters: characters as CharacterSet)!
        
        let conversation = createConversation()
        conversation?._imageUrlPath = imageName
        conversation?._message = "IMAGE"
        
        
        localCache.saveImage(UIImage(data: data)!, name: imageName)
        
        self.conversationDataSource.append(conversation!)
        
        self.updateUIAfterMessageSent()
        
        //get An instance of `AWSLocalContent` that represents data to be uploaded.
        let localContent = userFileManager.localContent(with: data, key: key)
        
        //start uploading from this function
        uploadLocalContent(localContent , conversation: conversation!)
    }
}


// MARK:- UIImagePickerControllerDelegate

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle image uploads
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image: UIImage = (info[UIImagePickerControllerOriginalImage] as! UIImage).resizeImage(200)!
            self.uploadWithData(UIImagePNGRepresentation(image)!)
        }
        
    }
}


//extension UIImageView {
//    public func imageFromUrl(urlString: String) {
//        if let url = NSURL(string: urlString) {
//            let request = NSURLRequest(URL: url)
//            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
//                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
//                if let imageData = data as NSData? {
//                    self.image = UIImage(data: imageData)
//
//                }
//            }
//        }
//    }
//}



extension UIImageView {
    
    
    
    fileprivate func downloadedFrom(_ url: URL) {
        
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data:Data?, response:URLResponse?, error:NSError?) in
            
            guard
                let httpURLRespone = response as? HTTPURLResponse, httpURLRespone.statusCode == 200,
                let data = data, error == nil,
                let image = UIImage(data: data)
                else {return}
            
            
            
            DispatchQueue.main.async(execute: {
                
                self.image = image
            })
            
            
            } as! (Data?, URLResponse?, Error?) -> Void) .resume()
        
    }
    func downloadWithUrl(_ link: String) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url)
    }
    
    
    
}
