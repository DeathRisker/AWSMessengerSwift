//
//  UIAlertController+Util.swift
//  MySampleApp
//
//  Modified on 15/10/2016.
//
//

import UIKit

extension UIAlertController {


    class func showErrorAlertWithMessage(_ message:String)  {
        
        
        
        
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }
        
        
        DispatchQueue.main.async(execute: {
        
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(doneAction)
            viewController.present(alertController, animated: true, completion: nil)
        })
        
        
    }


}
