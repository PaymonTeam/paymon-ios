import UIKit
import Foundation

class ProfileHeaderView : UIViewController {
    @IBOutlet weak var profileLogin: UILabel!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var profileAvatar: ObservableImageView!

    @IBOutlet weak var inviteFriendsImageView: UIImageView!
    @IBOutlet weak var updateImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateView()

        let updateClick = UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderView.updateClick(_:)))
        let inviteFriendsClick = UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderView.inviteFriendsClick(_:)))

        updateImageView.isUserInteractionEnabled = true
        updateImageView.addGestureRecognizer(updateClick)

        inviteFriendsImageView.isUserInteractionEnabled = true
        inviteFriendsImageView.addGestureRecognizer(inviteFriendsClick)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateView()
    }

    @objc func updateClick(_ sender: AnyObject) {

        let updateProfileView = storyboard?.instantiateViewController(withIdentifier: "UpdateProfileViewController") as! UpdateProfileViewController
        present(updateProfileView, animated: true)
    }

    @objc func inviteFriendsClick(_ sender: AnyObject) {

        let inviteFriendsView = storyboard?.instantiateViewController(withIdentifier: "InviteFriendsViewController") as! InviteFriendsViewController
        present(inviteFriendsView, animated: true)
    }

    func updateView() {

        if (User.currentUser != nil) {
            profileAvatar.setPhoto(ownerID: User.currentUser!.id, photoID: User.currentUser!.photoID)
            profileName.text! = Utils.formatUserName(User.currentUser!)
            profileLogin.text = "@\(User.currentUser!.login!)"
        }

    }
}
