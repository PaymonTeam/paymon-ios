import UIKit
import Foundation

class UpdateProfileViewController: UIViewController {
    @IBOutlet weak var indicatorUpdate: UIActivityIndicatorView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var borderConstraint: NSLayoutConstraint!
    let notificationCenter = NotificationCenter.default

    private var observerChangeHideIndicator : NSObjectProtocol!
    private var observerChangeTrue : NSObjectProtocol!
    private var observerChangeFalse : NSObjectProtocol!


    func stopIndicator(notofication : Notification) {
        DispatchQueue.main.async() {
            self.indicatorUpdate.stopAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerChangeTrue = NotificationCenter.default.addObserver(forName: NSNotification.Name("changeInfoTrue"), object: nil, queue: nil ){ notification in
            self.updateNavigationBar(visibleRight: true)
        }

        observerChangeFalse = NotificationCenter.default.addObserver(forName: NSNotification.Name("changeInfoFalse"), object: nil, queue: nil ){ notification in
            self.updateNavigationBar(visibleRight: false)
        }

        observerChangeHideIndicator = NotificationCenter.default.addObserver(forName: NSNotification.Name("hideIndicator"), object: nil, queue: nil, using: stopIndicator)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        borderConstraint.constant = 0.5

        updateNavigationBar(visibleRight: false)
    }

    func updateNavigationBar(visibleRight : Bool){

        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))
        let rightButton = UIBarButtonItem(image: UIImage(named: "check"), style: .plain, target: self, action: #selector(onNavBarItemRightClicked))

        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "Update Profile".localized

        if (!visibleRight) {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = rightButton
        }

        navigationBar.items = [navigationItem]
    }

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    @IBAction private func onNavBarItemRightClicked() {

        NotificationCenter.default.post(name: NSNotification.Name("updateProfile"), object: nil)

        updateNavigationBar(visibleRight: false)

        DispatchQueue.main.async() {
            self.indicatorUpdate.startAnimating()
        }

        self.view.endEditing(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerChangeTrue)
        NotificationCenter.default.removeObserver(observerChangeTrue)
        NotificationCenter.default.removeObserver(observerChangeHideIndicator)
    }
}
