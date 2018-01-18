

import UIKit

class SettingsNotificationTableViewController: UITableViewController {

    @IBOutlet weak var transactionsCell: UITableViewCell!
    @IBOutlet weak var vibrationCell: UITableViewCell!
    @IBOutlet weak var disturbCell: UITableViewCell!
    @IBOutlet weak var soundCell: UITableViewCell!
    
    let switchTransactions = UISwitch()
    let switchVibration = UISwitch()
    let switchWorry = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()

        transactionsCell.textLabel!.text! = "Transactions".localized
        vibrationCell.textLabel!.text! = "Vibration".localized
        soundCell.textLabel!.text! = "Sound".localized
        disturbCell.textLabel!.text! = "Do not disturb".localized

        transactionsCell.accessoryView = switchTransactions
        vibrationCell.accessoryView = switchVibration
        disturbCell.accessoryView = switchWorry

        loadSettings()

    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
        case 0: return "Messeges".localized
        case 1: return "Other".localized
        default: return "Other".localized
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveSettings()

    }

    func loadSettings() {

        switchWorry.setOn(User.notificationSwitchWorry, animated: true)
        switchVibration.setOn(User.notificationSwitchVibration, animated: true)
        switchTransactions.setOn(User.notificationSwitchTransactions, animated: true)

    }

    func saveSettings () {
        User.notificationSwitchWorry = switchWorry.isOn
        User.notificationSwitchVibration = switchVibration.isOn
        User.notificationSwitchTransactions = switchTransactions.isOn

        User.saveNotificationSettings()
    }
}
