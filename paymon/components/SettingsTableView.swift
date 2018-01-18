import UIKit

class SettingsTableView : UITableViewController{

    
    @IBOutlet weak var profileCell: UITableViewCell!
    @IBOutlet weak var notificationsTableViewCell: UITableViewCell!
    @IBOutlet weak var settingsAvatar: ObservableImageView!
    @IBOutlet weak var settingsName: UILabel!

    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet var faqCell: UILabel!
    @IBOutlet var securityCell: UILabel!
    @IBOutlet var logOutCell: UIButton!
    
    @IBOutlet weak var aboutTheProgramCell: UILabel!
    
    @IBAction func onLogoutClicked(_ sender: Any) {

        User.clearConfig()
        NetworkManager.instance.reconnect()

//        bookingCompleteAcknowledged()

    }
    func bookingCompleteAcknowledged(){

        dismiss(animated: true, completion: nil)

        if let topController = UIApplication.shared.keyWindow?.rootViewController {

            if let navController = topController.childViewControllers[0] as? UINavigationController{
                navController.popToRootViewController(animated: false)

                if let funnelController = navController.childViewControllers[0] as? SettingsViewController {
                    funnelController.removeFromParentViewController();
                    funnelController.view.removeFromSuperview();

                    let revealController = self.storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController

                    navController.addChildViewController(revealController)
                    navController.view.addSubview(revealController.view)
                }
            }
        }

    }

    @objc func showFaqDialog() {
        let faqAlertController = UIAlertController(title: "Open in browser?".localized, message: nil, preferredStyle: UIAlertControllerStyle.alert)

        faqAlertController.addAction(UIAlertAction(title: "Cancel".localized, style: UIAlertActionStyle.default, handler: { (action) in
            faqAlertController.dismiss(animated: true, completion: nil)
        }))
        faqAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
            UIApplication.shared.open(URL(string: "https://paymon.ru/faq-rus.html")! as URL, options: [:], completionHandler: nil)
        }))

        self.present(faqAlertController, animated: true, completion: nil)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let tap = UITapGestureRecognizer(target: self, action: #selector(showFaqDialog))
        faqCell.isUserInteractionEnabled = true
        faqCell.addGestureRecognizer(tap)

    }


    override func viewDidLoad() {
        super.viewDidLoad()

        updateView()

    }

    func updateView() {

        self.notificationsLabel.text! = "Notifications".localized
        self.securityCell.text! = "Security".localized

        self.aboutTheProgramCell.text! = "About the program".localized
        self.logOutCell.setTitle("Log out".localized, for: .normal)


        settingsAvatar.setPhoto(ownerID: User.currentUser!.id, photoID: User.currentUser!.photoID)
        settingsName.text! = Utils.formatUserName(User.currentUser!)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)


    }
}
