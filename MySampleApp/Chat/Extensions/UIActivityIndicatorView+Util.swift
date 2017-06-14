//
//  UIActivityIndicatorView+Util.swift
//  MySampleApp
//
//  Modified on 16/06/2016.
//
//

import UIKit

extension UIActivityIndicatorView {

    func startAnimationOnTop() {
        
        
        DispatchQueue.main.async(execute: {
           
            self.activityIndicatorViewStyle = .whiteLarge
            self.color = UIColor.black
            self.hidesWhenStopped = true
            
            let viewController = UIApplication.shared.keyWindow?.rootViewController
            self.center  = (viewController?.view.center)!
            
            viewController?.view.addSubview(self)
            
            self.startAnimating()
        })
        
        
    }
    
    
    func stopAnimationOnTop() {
        
        DispatchQueue.main.async(execute: {
           
            self.stopAnimating()
            self.removeFromSuperview()
            
        
        })
    }
    
}
