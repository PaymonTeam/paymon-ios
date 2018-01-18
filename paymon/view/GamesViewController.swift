import UIKit

class GamesViewController : UIViewController {
    
    
    @IBOutlet weak var labelTop: UILabel!
    @IBOutlet weak var labelBottom: UILabel!
    
    @IBOutlet weak var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Games".localized
        navigationBar.items = [navigationItem]

        labelTop.text = "I still learning how to play".localized
        labelBottom.text = "We'll play later".localized
//        navigationBar.autoSetDimension(.height, toSize: 64)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }


    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }


}
