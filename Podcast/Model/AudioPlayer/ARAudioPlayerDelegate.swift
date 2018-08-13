//
//  ARAudioPlayerDelegate.swift
//  StreamTest
//
//  Created by Andrew Roach on 7/21/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit


//required Methods
protocol ARAudioPlayerDelegate {
    func progressUpdated(timeUpdated: Float)
    func didChangeState(oldState: AudioPlayerState, newState: AudioPlayerState)
    func didFindDuration(duration: Float)
}


//Optional Methods
extension ARAudioPlayerDelegate {

}
