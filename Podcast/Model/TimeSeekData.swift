//
//  TimeSeekData.swift
//  Podcast
//
//  Created by Andrew Roach on 4/22/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class TimeSeekData: NSObject {

    
    func descriptionToTimeObjects(descript: String) -> [Int] {
        
        let colonIndexs = descript.indicesOf(string: ":")
        let allColonIndex = colonIndexs.map{ descript.index(descript.startIndex, offsetBy: $0)}
        var colonIndex = [String.Index]()
        
        //verify all indexs are good
        for element in allColonIndex {
            if let thirdIndex = descript.index(element, offsetBy: 1, limitedBy: descript.endIndex)  {
                if Int(String(descript[thirdIndex])) != nil {
                    colonIndex.append(element)
                }
            }
        }
        
        var arrayOfSeconds = [Int]()
        for index in colonIndex {
            arrayOfSeconds.append(timeStringToSeconds(descript, index))
        }
    
        return arrayOfSeconds
    }
    
    func secondsToString(seconds: Int) -> String {
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
        
        if s == 0 {
            return String(m) + ":" + String(s) + "0"
        } else if s < 10 {
            return String(m) + ":" + "0" + String(s)
        }
        else {
            return String(m) + ":" + String(s)
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    fileprivate func timeStringToSeconds(_ timeString: String, _ colonIndex: String.Index) -> Int {
        var minutesString = ""
        
        if let firstIndex = timeString.index(colonIndex, offsetBy: -2, limitedBy: timeString.startIndex)  {
            if let _ = Int(String(timeString[firstIndex])) {
                minutesString.append(timeString[firstIndex])
            }
        }
        
        if let secondIndex = timeString.index(colonIndex, offsetBy: -1, limitedBy: timeString.startIndex)  {
            if let _ = Int(String(timeString[secondIndex])) {
                minutesString.append(timeString[secondIndex])
            }
        }
        
        var secondsString = ""
        if let thirdIndex = timeString.index(colonIndex, offsetBy: 1, limitedBy: timeString.endIndex)  {
            if let _ = Int(String(timeString[thirdIndex])) {
                secondsString.append(timeString[thirdIndex])
            }
        }
        
        if let forthIndex = timeString.index(colonIndex, offsetBy: 2, limitedBy: timeString.endIndex)  {
            if let _ = Int(String(timeString[forthIndex])) {
                secondsString.append(timeString[forthIndex])
            }
        }
        var time = 0
        
        if let minutes = Int(minutesString) {
            time += minutes * 60
        }
        
        if let seconds = Int(secondsString) {
            time += seconds
        }
        
        return time
    }
    
    func timeStringToSeconds(timeString: String) -> Int {
        
        let colonLocation = timeString.indicesOf(string: ":")
        let colonIndex = timeString.index(timeString.startIndex, offsetBy: colonLocation.first!)
        
        return timeStringToSeconds(timeString, colonIndex)
    }
}

extension String {
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }
}

