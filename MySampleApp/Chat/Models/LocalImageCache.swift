//
//  LocalImageCache.swift
//  MySampleApp
//
//  Modified on 13/11/2016.
//

import UIKit

class LocalImageCache {
    
    
    var subDirectoryName:String!
    
    
    init(_subDirectoryName:String) {
        
        subDirectoryName = _subDirectoryName
        
        
        if let path = getSubDirectoryPath?.path {
            
            createDirectory(path)
            
        }
    }
    
   
    
    func createDirectory(_ directoryPath:String) {
        
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                
            } catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)")
            }
            
        }else{
            
            print("\(directoryPath) Directory is already exist")
            
        }
        
        
    }
    
    
    func getDocumentsDirectory() -> URL? {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let documentsDirectory = paths.first
        
        return documentsDirectory
        
    }
    
    func getChatRoomsDirectory() -> URL? {
        
        return getDocumentsDirectory()?.appendingPathComponent("ChatRooms", isDirectory: true)
        
    }
    
    var getSubDirectoryPath: URL? {
        
        return getChatRoomsDirectory()?.appendingPathComponent(subDirectoryName, isDirectory: true)
    
    }
    
    
    func filterImageName(_ imageName:String) -> String {
        
        return imageName.components(separatedBy: "/").last!
        
    }
    
    func saveImage(_ image:UIImage,name:String) {
        
        
        guard
            let data = UIImageJPEGRepresentation(image,1),
            let fileDirectory = getSubDirectoryPath?.path
            else {
                print(name + " is not saved")
                return
        }
        let filePath = fileDirectory + "/" + filterImageName(name)
        
        if (try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])) != nil {
        
            print(name + " is successfully saved")
        
        }
        
        
        
    }
    
    
    func loadImageWith(_ name:String) -> UIImage? {
        
        let imageFileName = filterImageName(name)
        
        if let filePath = getSubDirectoryPath?.appendingPathComponent(imageFileName).path {
        
            return UIImage(contentsOfFile: filePath)
        
        }
        
        return nil
    }
    
}
