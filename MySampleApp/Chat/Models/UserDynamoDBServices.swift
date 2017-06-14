//
//  ChatUserManager.swift
//  MySampleApp
//
//  Modified on 18/04/2016.
//  Copyright © 2016 Amazon. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB
import AWSMobileHubHelper



class UserDynamoDBServices: NSObject {
    
    
    var dynamoDBObjectMapper:AWSDynamoDBObjectMapper?
    
    
    override init() {
        
        super.init()
        
        dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
    }
    

    func loadUsersWithChatRoom(_ chatRoom:ChatRoom)->AWSTask<AnyObject> {
        
        
        
        var chatRoomRecipientIds = chatRoom._recipients
        
        chatRoomRecipientIds?.insert(chatRoom._userId!)
        
        
        let scanExpression = AWSDynamoDBScanExpression()
        
        
        var filters = Dictionary<String,String>()
        
        
        for index in  0...chatRoomRecipientIds!.count-1 {
            
            filters[":val\(index)"] = chatRoomRecipientIds![chatRoomRecipientIds!.index(chatRoomRecipientIds!.startIndex, offsetBy: index)]
        }
        
        
        let allKeys = Array(filters.keys)
        //let allValues = Array(filters.values)
        let keysExpression = allKeys.joined(separator: ",")
        scanExpression.filterExpression = "userId in (\(keysExpression))"
        
        
        
        
        scanExpression.expressionAttributeValues = filters
        
        
        return dynamoDBObjectMapper!.scan(UserProfile.self, expression:scanExpression).continue { (task) -> AnyObject? in
            
            if task.error != nil || task.exception != nil {
                print(task.exception)
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "Users are not found!"
                    ]))
            }
            
            if task.result != nil {
                print(task.result)
                
                let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput;
                
                
                for rect in paginatedOutput.items {
                    
                    print(rect)
                    
                }
                
                return AWSTask(result: paginatedOutput.items)
            }
            
            
            return nil
        }
        
    }
    
    
    func getUserFromPhoneNo(_ phoneNo:String)->AWSTask<AnyObject> {
        
        let scanExpression = AWSDynamoDBScanExpression()
        
        scanExpression.filterExpression = "phone = :val"
        scanExpression.expressionAttributeValues = [":val":phoneNo]
        
        return dynamoDBObjectMapper!.scan(UserProfile.self, expression:scanExpression).continue { (task) -> AnyObject? in
            
            if (task.error != nil) {
                print(task.error)
                
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "User not found"
                    ]))
            }
            
            if task.exception != nil {
                print(task.exception)
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "User not found"
                    ]))
            }
            
            if task.result != nil {
                print(task.result)
                
                let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput;
                
                
                if paginatedOutput.items.count > 0{
                    let _userProfile = paginatedOutput.items.first as! UserProfile
                    return AWSTask(result: _userProfile)
                }else{
                    return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                        NSLocalizedDescriptionKey: "User not found"
                        ]))
                }
                
            }
            return nil
        }
        
            
    }
    
    
    func saveUserPhoneNo(_ phoneNo:String , completion:@escaping (_ errorMessage:String?)->Void) {
        
        
        
        
        
        let userInfo = UserProfile();
        
        userInfo?._userId = AWSIdentityManager.defaultIdentityManager().identityId
        userInfo?._phone = phoneNo
        userInfo?._name = AWSIdentityManager.defaultIdentityManager().userName
        
        if let _deviceArn = UserProfile.getDeviceArn() {
        
            let targetArn = Set(arrayLiteral: _deviceArn)
            
            userInfo?._pushTargetArn = targetArn
            
        
        }
        
        
        
        //Save
        dynamoDBObjectMapper!.save(userInfo!).continue { (task) -> AnyObject? in
            
            if (task.error != nil) {
                print(task.error)
                
                completion(errorMessage: task.error?.localizedDescription)
            }
            
            if task.exception != nil {
                print(task.exception)
                completion(errorMessage: task.error?.debugDescription)
            }
            
            if task.result != nil {
                print(task.result)
                
                completion(errorMessage: nil)
            }
            
            
            return nil
        }
        
        
    }
    
    
    func updatePushTargetArn(_ userProfile:UserProfile , deviceArn:String)->AWSTask<AnyObject> {
        
      //user may have more than 1 device target Arn
        
        if userProfile._pushTargetArn == nil { 
            
            userProfile._pushTargetArn = Set<String>()
        
        }
            
        userProfile._pushTargetArn?.insert(deviceArn)
        
        
        return dynamoDBObjectMapper!.save(userProfile).continue { (task) -> AnyObject? in
            
            if task.error != nil || task.exception != nil {
                print(task.exception)
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "push target is not updated."
                    ]))
            }
            
            if task.result != nil {
                
                print(task.result)

                return AWSTask(result: "User push targetArn is updated")
            }
            
            return nil
        }
        
        
    }
    
    
    func isUserPhoneNoExist() -> AWSTask<AnyObject> {
        
        
        
        let scanExpression = AWSDynamoDBScanExpression()
        
        //scanExpression.limit = 1
        scanExpression.filterExpression = "userId = :val"
        scanExpression.expressionAttributeValues = [":val":AWSIdentityManager.defaultIdentityManager().identityId!]
        
        
        return dynamoDBObjectMapper!.scan(UserProfile.self, expression:scanExpression).continue { (task) -> AnyObject? in
            
            if task.error != nil || task.exception != nil {
                print(task.exception)
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "User is not registered yet."
                    ]))
            }
            
            if task.result != nil {
                
                print(task.result)
                
                let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput;
                
                return AWSTask(result: paginatedOutput.items)
            }
            
            
            
            return nil
        }
        
    }
}
