
import UIKit
import Foundation

class AboutProgramViewController : UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    var dict : NSDictionary?

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        titleLabel.text = "Paymon for iOS".localized

        self.view.addBackground()

        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "About the program".localized

        navigationBar.items = [navigationItem]

        let path = Bundle.main.path(forResource: "Info", ofType: "plist")

        dict = NSDictionary(contentsOfFile: path!)

        if let dictInfo = dict {
            versionLabel.text = ("version ".localized + "\(dictInfo["CFBundleShortVersionString"]!)"+"b")
        }

    }
}
