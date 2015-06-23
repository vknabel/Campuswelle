//
//  PodcastPlayer.swift
//  Campuswelle
//
//  Created by Valentin Knabel on 2015-04-19.
//  Copyright (c) 2015 Valentin Knabel. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

/// Converts a podcast to an player item.
private func toItem(podcast: Podcast) -> AVPlayerItem {
    return AVPlayerItem(URL: podcast.enclosure)
}

private let livestreamURL = NSURL(string: "http://campuswelle.uni-ulm.de:8000/listen.mp3")!
private let metaDataURL = NSURL(string: "http://campuswelle.uni-ulm.de/wp-content/themes/campuswelle/stream-meta_api.php?amount=1")!

/// The podcast player can play a livestream and podcasts.
public class PodcastPlayer {
    
    /// Stores the singleton instance.
    private static var _sharedInstance: PodcastPlayer?
    /// Use this property instead of init().
    public static var sharedInstance: PodcastPlayer {
        return _sharedInstance ?? PodcastPlayer()
    }
    
    /// Instances of this class shall only be instantiated from inside this class.
    private init() {
        PodcastPlayer._sharedInstance = self
        
        prepare()
    }
    
    /// Represents the currently playing items.
    public enum PlayingItem {
        /// Buffers a bit when paused.
        case PodcastItem(Podcast)
        /// Pausing and playing will take some time to prevent infinite buffering.
        /// Rewind and fast forward will be disabled.
        case LiveStreamItem
        /// All controls will be disabled.
        case EmptyItem
    }
    
    /// The currently played item. 
    /// For further details see PlaingItem's cases.
    public var currentItem: PlayingItem = .EmptyItem {
        didSet {
            switch currentItem {
            case .EmptyItem:
                player = nil
            case .LiveStreamItem:
                player = AVPlayer(URL: livestreamURL)
                self.refreshTitle()
            case .PodcastItem(let pod):
                player = AVPlayer(playerItem: toItem(pod))
            }
        }
    }
    
    /// This property stores the object returned for the seconds observer.
    private var observerObject: AnyObject? {
        willSet {
            guard let observerObject = observerObject else { return }
            self.player?.removeTimeObserver(observerObject)
        }
    }
    
    /// Set this property to receive time updates.
    public var secondsObserver: ((Double, Double)? -> Void)?  {
        didSet {
            guard let new = secondsObserver else { return }
            let time = CMTimeMake(1, 1)
            observerObject = self.player?.addPeriodicTimeObserverForInterval(time, queue: nil) { _ in
                guard let limit = self.player?.currentItem?.duration,
                    current = self.player?.currentTime()
                    where limit != kCMTimeIndefinite
                    else { new(nil);return }

                new((current.seconds, limit.seconds))
            }
        }
    }
    
    /// Stores the current player.
    private var player: AVPlayer? {
        willSet {
            self.observerObject = nil
        }
        didSet {
            defer { updateInfoCenter() }
            guard let _ = self.player else { return }
            self.play()
        }
    }
    
    /// Stores the least recent title. May not be the current item's title.
    private var leastRecentTitle: String?
    
    /// Stores an observer for a given title.
    public var titleObserver: ((String?) -> Void)? {
        didSet {
            titleObserver?(leastRecentTitle)
        }
    }
    private var titleTimer: NSTimer?
    
}

/// PodcastPlayer additions for playback.
public extension PodcastPlayer {
    
    /// Represents the external status of the current playback.
    public enum PlaybackStatus {
        case Playing
        case Paused
        case Empty
    }
    
    /// The current playback status of the podcast player.
    public var status: PlaybackStatus {
        switch currentItem {
        case .EmptyItem:
            return .Empty
        case .LiveStreamItem:
            guard let _ = player else { return .Paused }
            fallthrough
        default:
            guard let p = player else { fatalError("Playing empty track") }
            return p.rate == 0 ? .Paused : .Playing
        }
    }
    
    /// Initiates playback of a given podcast.
    public func playPodcast(podcast: Podcast, sender: UIResponder? = nil) {
        currentItem = .PodcastItem(podcast)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        sender?.becomeFirstResponder()
    }
    
    /// Re-plays currentItem, if not .EmptyItem. 
    /// May take some time to start for .LiveStreamItem.
    public func play(sender: UIResponder? = nil) {
        if case .LiveStreamItem = self.currentItem where player == nil {
            self.currentItem = .LiveStreamItem
        }
        
        player?.play()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        sender?.becomeFirstResponder()
    }
    
    /// Pauses playback of currentItem.
    public func pause(sender: UIResponder? = nil) {
        player?.pause()
        if case .LiveStreamItem = self.currentItem {
            self.player = nil
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        sender?.becomeFirstResponder()
    }
    
}

/// PodcastPlayer additions for meta info of the current item.
public extension PodcastPlayer {
    
    /// Typically a new title
    private func refreshTitleAfter(timeInterval: NSTimeInterval) {
        titleTimer = NSTimer(timeInterval: timeInterval, target: self, selector: Selector("refreshTitle"), userInfo: nil, repeats: false)
    }
    
    private func refreshTitle() {
        enum LocalError: ErrorType {
            /// Repeat after some seconds
            case LoadingError
        }
        
        do {
            let fetchedMetaData = NSData(contentsOfURL: metaDataURL)
            guard let metaData = fetchedMetaData else { throw LocalError.LoadingError }
            let json = try NSJSONSerialization.JSONObjectWithData(metaData, options: NSJSONReadingOptions.AllowFragments)
            guard let songs = json as? [NSDictionary],
                title = songs[0]["title"] as? String
                else {
                    print("Invalid server data")
                    return
            }
            self.leastRecentTitle = title
            titleObserver?(title)
            
            /// succeeded
            updateInfoCenter()
            refreshTitleAfter(120)
        }
        catch {
            refreshTitleAfter(5)
        }
        
    }
    
}


/// Internal PodcastPlayer additions.
private extension PodcastPlayer {
    
    /// Prepares the audio session.
    private func prepare() {
        // Set AudioSession
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: .DefaultToSpeaker)
        }
        catch {
            print(error)
        }
    }
    
    /// Updates the info center.
    private func updateInfoCenter() {
        switch currentItem {
        case .EmptyItem:
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
        case .LiveStreamItem:
            let artwork = MPMediaItemArtwork(image: UIImage(assetIdentifier: UIImage.AssetIdentifier.DefaultCover))
            let currentlyPlayingTrackInfo = [
                MPMediaItemPropertyArtist: "Campuswelle Live",
                MPMediaItemPropertyTitle: leastRecentTitle ?? "",
                MPMediaItemPropertyArtwork: artwork
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = currentlyPlayingTrackInfo
        case .PodcastItem(let pod):
            let artwork = MPMediaItemArtwork(image: UIImage(assetIdentifier: UIImage.AssetIdentifier.DefaultCover))
            let currentlyPlayingTrackInfo = [
                MPMediaItemPropertyArtist: "Campuswelle",
                MPMediaItemPropertyTitle: pod.article.title,
                MPMediaItemPropertyArtwork: artwork
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = currentlyPlayingTrackInfo
        }
    }
    
}

