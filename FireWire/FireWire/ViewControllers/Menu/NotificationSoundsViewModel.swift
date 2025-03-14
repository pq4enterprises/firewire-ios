//
//  NotificationSoundsViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/03/25.
//

import Foundation

class NotificationSoundsViewModel {
    let notificationSounds = ["Default": "servicebell", "Engine Ticket": "EngineTicket", "Ladder Ticket": "LadderTicket", "Engine Ladder Ticket": "EngineLadderTicket", "Special Unit": "SpecialUnit", "Acting Engine": "ActingEngineTicket", "Battalion": "BatalionTicket", "Division": "DivisionTicket", "Engine, Ladder, Battalion": "EngineLadderBatalionTicket", "Standby For Message": "StandbyForMessage", "Tones Only": "TonesOnly", "MDT Ring": "MDTRing"]

    var selectedSoundName: String? {
        return UserDefaults.standard.string(forKey: "pushSound")
    }

    func setNotificationSound(soundName: String, completion: @escaping (Bool) -> Void) {
        guard let name = notificationSounds[soundName],
              let bundleURL = Bundle.main.url(forResource: name, withExtension: "wav") else {
            debugPrint("Error: Sound file not found in bundle.")
            completion(false)
            return
        }

        let baseSoundURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Sounds")
        let soundsDirectoryURL = baseSoundURL.appendingPathComponent("custom.wav")

        // Create directory if it does not exist
        if !FileManager.default.fileExists(atPath: baseSoundURL.path) {
            do {
                try FileManager.default.createDirectory(at: baseSoundURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                debugPrint("Unable to create directory: \(error.localizedDescription)")
                completion(false)
                return
            }
        }

        debugPrint("Checking existing file: \(FileManager.default.fileExists(atPath: soundsDirectoryURL.path))")

        // Remove existing sound file if it exists
        try? FileManager.default.removeItem(at: soundsDirectoryURL)

        do {
            debugPrint("Copying from: \(bundleURL) to: \(soundsDirectoryURL)")
            try FileManager.default.copyItem(at: bundleURL, to: soundsDirectoryURL)
            UserDefaults.standard.set(soundName, forKey: "pushSound")
            completion(true) // Success
        } catch {
            debugPrint("Error copying file: \(error.localizedDescription)")
            completion(false) // Failure
        }
    }
}
