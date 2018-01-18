import UIKit
import Foundation

class ProfileTableInfoView : UITableViewController {
    
    @IBOutlet weak var countryInfo: UILabel!
    @IBOutlet weak var emailInfo: UILabel!
    @IBOutlet weak var phoneInfo: UILabel!
    @IBOutlet weak var cityInfo: UILabel!
    @IBOutlet weak var bdayInfo: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateView()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateView()

    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
        case 0: return "Contact information".localized
        case 1: return "Personal information".localized
        default: return "Personal information".localized
        }
    }

    func updateView() {
        if (User.currentUser!.city != nil && !User.currentUser!.city.isEmpty) {
            cityInfo.text = User.currentUser!.city
        } else {
            cityInfo.text = "Not choosen".localized
        }

        if (User.currentUser!.phoneNumber != nil && User.currentUser!.phoneNumber != 0) {
            phoneInfo.text = String(User.currentUser!.phoneNumber)
        } else {
            phoneInfo.text = "Not choosen".localized
        }
        if (User.currentUser!.email != nil && !User.currentUser!.email.isEmpty) {
            emailInfo.text = User.currentUser!.email
        } else {
            emailInfo.text = "Not choosen".localized
        }
        if (User.currentUser!.birthdate != nil && !User.currentUser!.birthdate.isEmpty) {
            bdayInfo.text = User.currentUser!.birthdate
        } else {
            bdayInfo.text = "Not choosen".localized
        }
        if (User.currentUser!.country != nil && !User.currentUser!.country.isEmpty) {
            countryInfo.text = User.currentUser!.country
        } else {
            countryInfo.text = "Not choosen".localized
        }
    }
}


