//
//  AudioManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 01/03/25.
//

import AVFoundation
import MediaPlayer

protocol AudioManagerDelegate {
    func audioManager(manager: AudioManager, didUpdateMetadata metadata: String)
}

class AudioManager: NSObject {
    let timedMetadataKey = "timedMetadata"
    static let shared = AudioManager()
    var delegate: AudioManagerDelegate?
    
    var player: AVPlayer?
    
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil && player != nil
    }
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            debugPrint("Audio session configured for background playback.")
        }  catch let error as NSError {
            debugPrint("Audio Session Error: \(error.localizedDescription) - Code: \(error.code)")
        }
    }
    
    func streamAudioFromURL(url: URL, feedTitle: String = "") {
        stopStreaming()
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: item)
        item.addObserver(self, forKeyPath: timedMetadataKey, options: [.new], context: nil)
        
        player?.play()
        updateNowPlayingInfo(artist: feedTitle)
    }
    
    private func updateNowPlayingInfo(title: String = "FireWire", artist: String = "Live Stream") {
        guard let player = player else { return }

        // Create artwork for the now playing info
        let artworkImage: UIImage = FWImage.appLogo!
        let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { size in
            return artworkImage
        }

        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        // Set the updated Now Playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            self?.updateNowPlayingInfo()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            self?.updateNowPlayingInfo()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying == true {
                self?.player?.pause()
            } else {
                self?.player?.play()
            }
            self?.updateNowPlayingInfo()
            return .success
        }
    }
    
    func stopStreaming() {
        player?.pause()
    }
}
