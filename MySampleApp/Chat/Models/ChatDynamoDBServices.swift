//
//  ChatDataManager.swift
//  MySampleApp
//
//  Modified on 18/04/2016.
//  Copyright © 2016 Amazon. All rights reserved.
//

import Foundation
import UIKit

import AWSDynamoDB
import AWSMobileHubHelper




class ChatDynamoDBServices: NSObject {
    
    
    var dynamoDBObjectMapper:AWSDynamoDBObjectMapper?
    
    
    override init() {
        
        super.init()
        
        dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
    }
    
    
    //MARK: ChatRoom Servcies
    
    
    func getChatRoomWithChatRoomId(_ chatRoomId:String) -> AWSTask<AnyObject> {
        
        
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        
        queryExpression.indexName = "ByCreationDate"
        queryExpression.keyConditionExpression = "#chatRoomId = :chatRoomId"
        queryExpression.expressionAttributeNames = [
            "#chatRoomId": "chatRoomId",
            
        ]
        queryExpression.expressionAttributeValues = [
            
            ":chatRoomId": chatRoomId,
        ]
        
        return dynamoDBObjectMapper!.query(ChatRoom.self, expression:queryExpression).continueWith {
            (task) -> AWSTask<AnyObject> in
            
            
            if task.result != nil {
                
                
                let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result!;
                
                
                
                if let chatRoomObject = paginatedOutput.items.first {
                    
                    return AWSTask(result: chatRoomObject)
                    
                }
                
                
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "Chat room is not found"
                    ]))
            }
            
            
            return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                NSLocalizedDescriptionKey: "Chat room is not found"
                ]))
        }
        
        
    }
    
    func loadUserChatRooms()->AWSTask<AnyObject> {
        
        
        
            let loggedInUserId = AWSIdentityManager.default().identityId!
            
            let scanExpression = AWSDynamoDBScanExpression()
            
            scanExpression.filterExpression = "userId = :userId or contains(recipients, :userId)"
            
            scanExpression.expressionAttributeValues = [":userId":loggedInUserId]
            
            
            return dynamoDBObjectMapper!.scan(ChatRoom.self, expression:scanExpression).continueWith { (task) -> AWSTask<AnyObject> in
                
                
                if let _result = task.result {
                    
                    print(_result)
                    
                    let paginatedOutput:AWSDynamoDBPaginatedOutput = _result ;
                    
                    return AWSTask(result: (paginatedOutput.items as NSArray))
                }
                
                
                if let _error = task.error {
                
                    print(_error)
                }
                
                
                
                return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "Recipient is not found"
                    ]))
            }
            
        
    }
    
    
    
    
    func saveNewChatRoom(_ chatRoomName:String?,userProfiles:[UserProfile])->AWSTask<AnyObject> {
        
        let chatRoom = ChatRoom();
        
        
        chatRoom?._chatRoomId = UUID().uuidString
        chatRoom?._createdAt = Date().formattedISO8601
        chatRoom?._userId = AWSIdentityManager.default().identityId!
        chatRoom?._name = chatRoomName
        chatRoom?._recipients = Set<String>()
        
        for userProfile in userProfiles {
            chatRoom?._recipients?.insert(userProfile._userId!)
        }
        
        //Save
        return dynamoDBObjectMapper!.save(chatRoom!).continueWith { (task) -> AWSTask<AnyObject> in

            
            if task.result != nil {
                
                return AWSTask(result: NSString(string:"Chat Room Created"))
            }
            
            
            return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                NSLocalizedDescriptionKey: "Chat room is not created"
                ]))
        }
    }
    
    
    
    //MARK: Conversation Servcies
    
    
    func loadConversation(_ chatRoomId:String) -> AWSTask<AnyObject> {
        
        
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        
        queryExpression.indexName = "ByCreationDate"
        queryExpression.keyConditionExpression = "#chatRoomId = :chatRoomId"
        queryExpression.expressionAttributeNames = [
            "#chatRoomId": "chatRoomId",
            
        ]
        queryExpression.expressionAttributeValues = [
            
            ":chatRoomId": chatRoomId,
        ]
        
        
        
        return dynamoDBObjectMapper!.query(Conversation.self, expression:queryExpression).continueWith { (task) -> AWSTask<AnyObject> in
            
            
            if task.result != nil {
                print(task.result!)
                
                let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result!;
                
                
                for rect in paginatedOutput.items {
                    
                    print(rect)
                    
                }
                
                return AWSTask(result: (paginatedOutput.items) as NSArray)
            }
            
            
            return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                NSLocalizedDescriptionKey: "Chat room is not created"
                ]))
        }
        
        
    }
    
    
    func sendMessage(_ conversation:Conversation)->AWSTask<AnyObject> {
        
        
        
        
        //Save
        return dynamoDBObjectMapper!.save(conversation).continueWith { (task) -> AWSTask<AnyObject> in

            if task.result != nil {
                
                
                return AWSTask(result: NSString(string:"Message Sent"))
            }
            
            
            return AWSTask(error: NSError(domain: "", code: -11, userInfo: [
                NSLocalizedDescriptionKey: "Chat room is not created"
                ]))
        }
        
        
        
    }
    
    
    
    
    
    
}


