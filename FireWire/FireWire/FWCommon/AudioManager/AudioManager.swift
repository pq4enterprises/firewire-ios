//
//  AudioManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 01/03/25.
//

import AVFoundation
import Foundation

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
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
    }
    
    func streamAudioFromURL(url: URL) {
        stopStreaming()
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        item.addObserver(self, forKeyPath: timedMetadataKey, options: [.new], context: nil)
        player?.play()
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
