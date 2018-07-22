//
//  ARAudioPlayerState.swift
//  StreamTest
//
//  Created by Andrew Roach on 7/21/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//


import Foundation

public enum AudioPlayerState {
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
    case error
    
    /// A boolean value indicating is self = `buffering`.
    var isBuffering: Bool {
        if case .buffering = self {
            return true
        }
        return false
    }
    
    /// A boolean value indicating is self = `playing`.
    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
    
    /// A boolean value indicating is self = `paused`.
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }
    
    /// A boolean value indicating is self = `stopped`.
    var isStopped: Bool {
        if case .stopped = self {
            return true
        }
        return false
    }
    
    /// A boolean value indicating is self = `waitingForConnection`.
    var isWaitingForConnection: Bool {
        if case .waitingForConnection = self {
            return true
        }
        return false
    }
    
    
    /// The error if self = `failed`.
    var error: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    
}

extension AudioPlayerState: Equatable {}

public func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
    if (lhs.isBuffering && rhs.isBuffering) || (lhs.isPlaying && rhs.isPlaying) ||
        (lhs.isPaused && rhs.isPaused) || (lhs.isStopped && rhs.isStopped) ||
        (lhs.isWaitingForConnection && rhs.isWaitingForConnection) || (lhs.error && rhs.error) {
        return true
    }

    return false
}
