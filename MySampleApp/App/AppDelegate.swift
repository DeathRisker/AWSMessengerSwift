//
//  AppDelegate.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.2
//

import UIKit
import AWSMobileHubHelper
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        let isLounched =  AWSMobileClient.sharedInstance.didFinishLaunching(application, withOptions: launchOptions)
        
        
        if AWSSignInManager.sharedInstance().isLoggedIn == false {
            
            
            
            let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
            let signInViewController = storyboard.instantiateViewController(withIdentifier: "SignIn") as! LogInViewController
            
            
            self.window?.rootViewController =  signInViewController
        }
        
        
        return isLounched
    }
    
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // print("application application: \(application.description), openURL: \(url.absoluteURL), sourceApplication: \(sourceApplication)")
        return AWSMobileClient.sharedInstance.withApplication(application, withURL: url, withSourceApplication: sourceApplication, withAnnotation: annotation)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AWSMobileClient.sharedInstance.applicationDidBecomeActive(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // Clear the badge icon when you open the app.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AWSMobileClient.sharedInstance.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AWSMobileClient.sharedInstance.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        AWSMobileClient.sharedInstance.application(application, didReceiveRemoteNotification: userInfo)
        
        
        if let chatRoomId = userInfo["chatRoomId"] as? String {
            
            print(chatRoomId)
            
            
            ChatDynamoDBServices().getChatRoomWithChatRoomId(chatRoomId).continueWith{ (task) -> AnyObject? in
                
                
                if let chatRoom = task.result as? ChatRoom {
                    
                    print(chatRoom)
                    
                    
                    
                    var defaultMessage = ""
                    (userInfo as NSDictionary).value(forKeyPath: "aps.alert")
                    if let _defaultMessage = (userInfo as NSDictionary).value(forKeyPath: "aps.alert") as! String! {
                        
                        defaultMessage = _defaultMessage
                        
                    }
                    
                    self.showMessageInConversation(chatRoom,defaultMessage: defaultMessage)
                    
                    
                    
                }
                
                return nil
            }
            
        }
        
        
        
    }
    
    func showMessageInConversation(_ chatRoom:ChatRoom , defaultMessage:String) {
        
        
        guard let _navigationController = self.window?.rootViewController as? UINavigationController else{
            
            showPushAlert(defaultMessage)
            return
        }
        
        
        guard let conversationVC = _navigationController.topViewController as? ConversationViewController, conversationVC.selectedChatRoom!._chatRoomId == chatRoom._chatRoomId else{
            
            showPushAlert(defaultMessage)
            return
        }
        
        
        conversationVC.selectedChatRoom = chatRoom
        
        conversationVC.loadRecipientsAndConversations(false)
        
        print(conversationVC)
        
        
    }
    
    func showPushAlert(_ defaultMessage:String) {
        
        DispatchQueue.main.async(execute: {
            
            let alertController = UIAlertController(title: "Message", message: defaultMessage, preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(doneAction)
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            
        })
    }
    
}
