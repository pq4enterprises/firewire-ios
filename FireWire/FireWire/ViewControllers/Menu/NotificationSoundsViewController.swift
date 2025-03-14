//
//  NotificationSoundsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/03/25.
//

import AVFoundation
import UIKit

class NotificationSoundsViewController: UIViewController {
    var coordinator: HomeCoordinator?
    let viewModel = NotificationSoundsViewModel()
    var player: AVAudioPlayer?

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.sectionHeaderTopPadding = 0 // iOS 15+ to avoid space above section headers

        tableView.register(NotificationSoundsCell.nib(), forCellReuseIdentifier: NotificationSoundsCell.identifier)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> NotificationSoundsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NotificationSoundsViewController") as! NotificationSoundsViewController
        return viewController
    }
}

extension NotificationSoundsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.notificationSounds.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationSoundsCell.identifier) as! NotificationSoundsCell
        let soundKeys = Array(viewModel.notificationSounds.keys.sorted())
        let soundName = soundKeys[indexPath.row]

        let isSelected = soundName == viewModel.selectedSoundName
        cell.setupView(soundName, selectSound: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = Array(viewModel.notificationSounds.keys.sorted())[indexPath.row]
        guard let soundValue = viewModel.notificationSounds[key] else { return }
        showAlert(title: "Sound Options", message: "Choose an option", actions: [UIAlertAction(title: "Preview Sound", style: .default, handler: { _ in
            if let soundURL = Bundle.main.url(forResource: soundValue, withExtension: "wav") {
                do {
                    self.player = try AVAudioPlayer(contentsOf: soundURL)
                    self.player?.prepareToPlay()
                    self.player?.play()
                } catch {
                    print("Error playing sound: \(error.localizedDescription)")
                }
            }
        }), UIAlertAction(title: "Set Sound", style: .default, handler: { _ in
            guard self.unlockPremiumFeatureIfValid() == false else { return }
            self.viewModel.setNotificationSound(soundName: key) { success in
                if success {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        })], cancel: true)
    }
}
