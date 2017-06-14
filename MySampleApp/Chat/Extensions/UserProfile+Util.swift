//
//  UserProfile+Util.swift
//  MySampleApp
//
//  Modified on 05/06/2016.
//
//

import AWSMobileHubHelper

extension UserProfile {

    class func getDeviceArn() -> String? {
    
        let pushManager: AWSPushManager = AWSPushManager.default()
        
        
        
        if let _endpointARN = pushManager.endpointARN {
           // pushManager.enabled = true
           return _endpointARN
        }else{
            pushManager.registerForPushNotifications()
        }
        
        return nil
    }

}
