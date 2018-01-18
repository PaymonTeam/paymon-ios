import UIKit

class SettingsViewController : UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var borderConstraint: NSLayoutConstraint!
    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        borderConstraint.constant = 0.5
        
        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "Settings".localized

        navigationBar.items = [navigationItem]
    }
}
