//
//  NSBundle+Util.swift
//  MySampleApp
//

import UIKit

extension Bundle {
    
    
   
    class func getRegionFromPushManager() -> String {
        
        if let awsInfo = Bundle.main.infoDictionary?["AWS"] {
            
            
            if let region = awsInfo["PushManager"]??["Default"]??["Region"] as? String {
                
                return region
            }
            
            
            
        }
        
        
        return ""
    }
    
    
    class func getRegionFromCreadentialProvider() -> String {
        
        if let awsInfo = Bundle.main.infoDictionary?["AWS"] {
            
            
            if let region = awsInfo["CredentialsProvider"]??["CognitoIdentity"]??["Default"]??["Region"] as? String {
                
                return region
            }
            
            
            
        }
        
        
        return ""
    }

    
    public class func getPushNotificationRegion() -> String {
        
        if let awsInfo = Bundle.main.infoDictionary?["AWS"] {
            
            
            if let poolId = awsInfo["CredentialsProvider"]??["CognitoIdentity"]??["Default"]??["PoolId"] as? String {
                
                return poolId
            }
            
            
            
        }
        
        
        return ""
    }
    
    public class func getPoolId() -> String {
        
        if let awsInfo = Bundle.main.infoDictionary?["AWS"] {
            
            
            if let poolId = awsInfo["CredentialsProvider"]??["CognitoIdentity"]??["Default"]??["PoolId"] as? String {
                
                return poolId
            }
            
            
            
        }
        
        
        return ""
    }
    
    
    public class func dynamoDBTableName(_ tableName:String) -> String {
        
        if let awsInfo = Bundle.main.infoDictionary?["DynamoDBTables"] {
            
            
            if let tableName = awsInfo[tableName] as? String {
                
                return tableName
            }
            
            
            
        }
        
        
        return ""
    }
    
}
