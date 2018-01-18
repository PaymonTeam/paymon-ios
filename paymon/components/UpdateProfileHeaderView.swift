import UIKit
import Foundation

class UpdateProfileHeaderView : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var updateProfileAvatar: ObservableImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    var activityView:UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.color = UIColor(r: 0, g: 122, b: 255)
        activityView.center = CGPoint(x: updateProfileAvatar.center.x - updateProfileAvatar.frame.origin.x, y: updateProfileAvatar.center.y - updateProfileAvatar.frame.origin.y)
        updateProfileAvatar.addSubview(activityView)
        activityView.stopAnimating()

        choosePhotoButton.setTitle("Change photo".localized, for: .normal)

        let tapper = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
        if let user = User.currentUser {
            updateProfileAvatar.setPhoto(ownerID: user.id, photoID: user.photoID)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func onChangePhotoClicked(_ sender: UIButton) {
        let cardPicker = UIImagePickerController()
        cardPicker.allowsEditing = true
        cardPicker.delegate = self
        cardPicker.sourceType = .photoLibrary //.savedPhotosAlbum
//        presentModalViewController(cardPicker, animated: true)
        present(cardPicker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage, let currentUser = User.currentUser {
//            updateProfileAvatar.image = image

            guard let photo = MediaManager.instance.savePhoto(image: image, user: currentUser) else {
                return
            }
            guard let photoFile = MediaManager.instance.getFile(ownerID: photo.user_id, fileID: photo.id) else {
                return
            }
            print("file saved \(photoFile)")
            let packet = RPC.PM_setProfilePhoto()
            packet.photo = photo
            let oldPhotoID = currentUser.photoID!
            let photoID = photo.id!

            self.updateProfileAvatar.setPhoto(photo: photo)

            ObservableMediaManager.instance.postPhotoUpdateIDNotification(oldPhotoID: oldPhotoID, newPhotoID: photoID)

            DispatchQueue.main.async {
                self.activityView.startAnimating()
            }

            NetworkManager.instance.sendPacket(packet) { packet, error in
                if (packet is RPC.PM_boolTrue) {
                    Utils.stageQueue.run {
                        PMFileManager.instance.startUploading(photo: photo, onFinished: {
//                            dialog.dismiss()
                            print("File has uploaded")
                            DispatchQueue.main.async {
                                self.activityView.stopAnimating()
                            }
                        }, onError: { code in
                            print("file upload failed \(code)")
                            DispatchQueue.main.async {
                                self.activityView.stopAnimating()
                            }
                        }, onProgress: { p in
//                            dialog.cancel();
                        })
                    }
                } else {
//                    dialog.cancel();
                    DispatchQueue.main.async {
                        self.activityView.stopAnimating()
                    }
                    PMFileManager.instance.cancelFileUpload(fileID: photoID);
                }
            }
        }
    }
}
