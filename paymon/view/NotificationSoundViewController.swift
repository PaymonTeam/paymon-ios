import UIKit

class NotificationSoundViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "Sounds".localized

        navigationBar.items = [navigationItem]

    }
}
