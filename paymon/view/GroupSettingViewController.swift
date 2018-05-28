//
//  GroupSettingViewController.swift
//  paymon
//
//  Created by infoobjects on 5/26/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

class GroupSettingContactsTableViewCell : UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var photo: ObservableImageView!
    @IBOutlet weak var checkBox: UIImageView!
    @IBOutlet weak var btnCross: UIButton!
}

class GroupSettingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var btnGroupImage: UIButton!
    @IBOutlet weak var tblParticipants: UITableView!
    @IBOutlet weak var btnAddParticipants: UIButton!
    @IBOutlet weak var txtfTitle: UITextField!
    var users:[RPC.UserObject] = []
    var chatID: Int32!
    var participants = SharedArray<RPC.UserObject>()
    var isCreator:Bool = false
    var creatorID:Int32!
    var group:RPC.Group!
    var activityView:UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.color = UIColor(r: 0, g: 122, b: 255)
        activityView.center = self.view.center
        self.view.addSubview(activityView)
        activityView.stopAnimating()
        participants = MessageManager.instance.groupsUsers.value(forKey: chatID)!
        group = MessageManager.instance.groups[chatID]!
        txtfTitle.text = group.title
        creatorID = group.creatorID;
        isCreator = (creatorID == User.currentUser?.id);
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: - IBActions
    
    @IBAction func btnAddParticipantsTapped(_ sender: Any) {
        let groupView = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        groupView.isGroupAlreadyCreated = true
        groupView.chatID = chatID
        groupView.setValue(group.title, forKey: "title")
        present(groupView, animated: false, completion: nil)
    }
    
    @IBAction func btnGroupImageTapped(_ sender: Any) {
        let cardPicker = UIImagePickerController()
        cardPicker.allowsEditing = true
        cardPicker.delegate = self
        cardPicker.sourceType = .photoLibrary
        present(cardPicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage, let currentUser = User.currentUser {
            guard let photo = MediaManager.instance.savePhoto(image: image, user: currentUser) else {
                return
            }
            guard let photoFile = MediaManager.instance.getFile(ownerID: photo.user_id, fileID: photo.id) else {
                return
            }
            print("file saved \(photoFile)")
            let packet = RPC.PM_group_setPhoto()
            packet.photo = photo
            packet.id = chatID
            let oldPhotoID = group.photo.id!
            let photoID = photo.id!
            btnGroupImage.setImage(image, for: .normal)
        ObservableMediaManager.instance.postPhotoUpdateIDNotification(oldPhotoID: oldPhotoID, newPhotoID: photoID)

            DispatchQueue.main.async {
                self.activityView.startAnimating()
            }
            
            NetworkManager.instance.sendPacket(packet) { packet, error in
                if (packet is RPC.PM_boolTrue) {
                    Utils.stageQueue.run {
                        PMFileManager.instance.startUploading(photo: photo, onFinished: {
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
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        self.activityView.stopAnimating()
                    }
                    PMFileManager.instance.cancelFileUpload(fileID: photoID);
                }
            }
        }
    }
    @IBAction func btnBackTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func btnDoneTapped(_ sender: Any) {
        if txtfTitle.text != group.title {
            let setSettings = RPC.PM_group_setSettings()
            setSettings.id = chatID;
            setSettings.title = txtfTitle.text!;
            NetworkManager.instance.sendPacket(setSettings) { response, e in
                let manager = MessageManager.instance
                if (response != nil) {
                    DispatchQueue.main.async {
                        manager.groups[self.chatID]?.title = self.txtfTitle.text!
                    }
                }
            }
        }
    }
    //MARK: - TableViewDelegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let data = participants[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSettingContactsTableViewCell") as! GroupSettingContactsTableViewCell
        cell.name.text = Utils.formatUserName(data)
        cell.photo.setPhoto(ownerID: data.id, photoID: data.photoID)
        cell.btnCross.isHidden = true
        if data.id != creatorID {
            cell.btnCross.addTarget(self, action:#selector(btnCrossTapped), for: .touchUpInside)
            cell.btnCross.tag = row
            cell.btnCross.isHidden = false
        }
        return cell
    }
    
    func btnCrossTapped(sender:UIButton) {
        let user = participants[sender.tag]
        let alert = UIAlertController(title: "Are you sure to remove this user".localized, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "CANCEL".localized, style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (nil) in
            
            let removeParticipant = RPC.PM_group_removeParticipant();
            removeParticipant.id = self.chatID;
            removeParticipant.userID = user.id;
            NetworkManager.instance.sendPacket(removeParticipant) { response, e in
                if (response != nil) {
                    self.participants.remove(at: sender.tag)
                    self.tblParticipants.reloadData()
                }
            }
        }))
        alert.addTextField { (textField) in
            textField.placeholder = "Enter group title"
        }
        self.present(alert, animated: true, completion: nil)
    }

}
