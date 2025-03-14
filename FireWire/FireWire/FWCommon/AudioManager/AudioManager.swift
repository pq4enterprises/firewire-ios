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
               try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
               try AVAudioSession.sharedInstance().setActive(true)
               print("Audio session configured for background playback.")
           } catch {
               print("Audio Session Error: \(error)")
           }
       }

    func streamAudioFromURL(url: URL) {
        stopStreaming()
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: item)
        item.addObserver(self, forKeyPath: timedMetadataKey, options: [.new], context: nil)

        player?.play()
        updateNowPlayingInfo()
    }

    private func updateNowPlayingInfo() {
        guard let player = player else { return }

        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Fire Wire"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Live Stream"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(player.currentItem?.asset.duration ?? CMTime.zero)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate

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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let playerItem = object as? AVPlayerItem, let metadataArray = playerItem.timedMetadata, keyPath == "timedMetadata" {
            for metaData in metadataArray {
                if let metadata = metaData.stringValue {
                    delegate?.audioManager(manager: self, didUpdateMetadata: metadata)
                }
            }
        }
    }
}
