//
//  UIImageView+Util.swift
//  MySampleApp
//
//  Modified on 09/11/2016.
//
//

import UIKit

extension UIImage {


    func resizeImage(_ newWidth: CGFloat) -> UIImage? {
        
        var imageWidth = newWidth
        
        if self.size.width < imageWidth {
            
            imageWidth = self.size.width
        }
    
        
        
        let scale = imageWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    
    }


}
