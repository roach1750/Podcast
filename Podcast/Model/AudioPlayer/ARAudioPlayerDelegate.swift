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
    func progressUpdated(_sender: ARAudioPlayer, timeUpdated: Float)
    func didChangeState(_sender: ARAudioPlayer, oldState: AudioPlayerState, newState: AudioPlayerState)
    func didFindDuration(_sender: ARAudioPlayer, duration: Float)
}


//Optional Methods
extension ARAudioPlayerDelegate {

}
