import UIKit
import Foundation
import UserNotifications

class ProfileViewController: UIViewController {

    
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var borderConstraint: NSLayoutConstraint!

    @objc func settingsClick(_ sender: AnyObject) {

//        self.scheduleNotification(event: "Messagge", body:"privet", interval: 3)

        let settingsView = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        settingsView.modalPresentationStyle = .overCurrentContext
        present(settingsView, animated: true)
    }

//    func scheduleNotification(event : String, body : String, interval: TimeInterval) {
//        let content = UNMutableNotificationContent()
//
//        let endIndex = User.notificationSound.index(User.notificationSound.endIndex, offsetBy: -4)
//        let sound = User.notificationSound.substring(to: endIndex)
//
//        content.title = event
//        content.body = body
//        content.categoryIdentifier = "CALLINNOTIFICATION"
//        content.sound = UNNotificationSound(named: sound)
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
//        let identifier = "id_\(event)"
//        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//
//        let center = UNUserNotificationCenter.current()
//        center.add(request)
//    }


    override func viewDidLoad() {
        super.viewDidLoad()

        borderConstraint.constant = 0.5

        let navigationItem = UINavigationItem()

        let settingsButton = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(settingsClick(_:)))

        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.title = "Profile".localized

        navigationBar.items = [navigationItem]

    }
}

