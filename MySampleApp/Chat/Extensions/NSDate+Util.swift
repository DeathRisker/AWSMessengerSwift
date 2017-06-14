//
//  NSDate+Util.swift
//  MySampleApp
//
//  Modified on 08/06/2016.
//
//

let ISO8601DateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

import Foundation

extension Foundation.Date {
    struct Date {
        static let formatterISO8601: DateFormatter = {
            
            let dateFormatter = DateFormatter()
            //dateFormatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
            let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = enUSPosixLocale
            dateFormatter.dateFormat = ISO8601DateFormat
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            
//            let formatter = NSDateFormatter()
//            formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
//            formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
//            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
//            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            return dateFormatter
        }()
    }
    
    var formattedISO8601: String { return Date.formatterISO8601.string(from: self) }
    
    func formattedISO8601Date(_ iso8601String:String) -> Foundation.Date {
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ISO8601DateFormat
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        return  dateFormatter.date(from: iso8601String)!
    }
    
    func chatRoomFormatted(_ iso8601String:String) -> String {
        
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ISO8601DateFormat
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        let date = dateFormatter.date(from: iso8601String)

        dateFormatter.dateFormat = "dd/MM/yy"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date!)
        
    }
    
    
    func conversationDateFormatted(_ iso8601String:String) -> String {
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ISO8601DateFormat
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        let date = dateFormatter.date(from: iso8601String)
        
        dateFormatter.dateFormat = "EEE, MMM dd"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date!)
        
    }

    
    func conversationTimeFormatted(_ iso8601String:String) -> String {
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ISO8601DateFormat
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        let date = dateFormatter.date(from: iso8601String)
        
        dateFormatter.dateFormat = "MMM dd, hh:mm a"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date!)
        
    }
    
    
}



