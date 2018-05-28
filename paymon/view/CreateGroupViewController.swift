//
//  CreateGroupViewController.swift
//  paymon
//
//  Created by infoobjects on 5/21/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

class GroupContactsTableViewCell : UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var photo: ObservableImageView!
    @IBOutlet weak var checkBox: UIImageView!
}

class GroupContactsHeaderView : UIView {
    @IBOutlet weak var txtVContacts: UITextView!
}

class CreateGroupViewController: UIViewController , UITableViewDataSource, UITableViewDelegate{
    @IBOutlet weak var btnCreateGroup: UIBarButtonItem!
    @IBOutlet weak var tblVContacts: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var usersData:[RPC.UserObject] = []
    var selectedUserData:NSMutableArray = []
    var isGroupAlreadyCreated:Bool = false
    var chatID: Int32!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for user in MessageManager.instance.userContacts.values {
            usersData.append(user)
        }
        if isGroupAlreadyCreated {
            let navigationItem = UINavigationItem()
            navigationItem.title = value(forKey: "title") as? String
            if navigationBar.items != nil {
                navigationBar.items!.append(navigationItem)
            }
        }
        self.setTableHeaderView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions
    
    @IBAction func createGroupAction(_ sender: Any) {
        if isGroupAlreadyCreated {
            let addParticipant:RPC.PM_group_addParticipants! =  RPC.PM_group_addParticipants();
            addParticipant.userIDs = []
            for user in self.selectedUserData {
                let data = user as! RPC.UserObject
                addParticipant.userIDs.append(data.id)
            }
            if addParticipant.userIDs.isEmpty {
                return ;
            }
            
            addParticipant.id = chatID;
            NetworkManager.instance.sendPacket(addParticipant) { response, e in
                let manager = MessageManager.instance
                if (response != nil) {
                    let group:RPC.Group! = response as! RPC.Group!
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            if selectedUserData.count > 0 {
                let alert = UIAlertController(title: "CREATE GROUP".localized, message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "CANCEL".localized, style: .default, handler: { (action) in
                    
                }))
                alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (nil) in
                    let textField = alert.textFields![0] as UITextField
                    if !(textField.text?.isEmpty)! {
                        let createGroup = RPC.PM_createGroup()
                        createGroup.userIDs = []
                        for user in self.selectedUserData {
                            let data = user as! RPC.UserObject
                            createGroup.userIDs.append(data.id)
                        }
                        createGroup.title = textField.text;
                        NetworkManager.instance.sendPacket(createGroup) { response, e in
                            let manager = MessageManager.instance
                            if (response != nil) {
                                let group:RPC.Group! = response as! RPC.Group!
                                manager.putGroup(group)
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }))
                alert.addTextField { (textField) in
                    textField.placeholder = "Enter group title"
                }
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - TableViewDelegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let data = usersData[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupContactsTableViewCell") as! GroupContactsTableViewCell
        cell.name.text = Utils.formatUserName(data)
        cell.photo.setPhoto(ownerID: data.id, photoID: data.photoID)
        if selectedUserData.contains(data) {
            cell.checkBox.image = UIImage(named: "checked-checkbox")
        } else {
            cell.checkBox.image = UIImage(named: "unchecked-checkbox")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let data:RPC.UserObject = usersData[row]
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedUserData.contains(data) {
            selectedUserData.removeObject(identicalTo: data)
        } else {
            selectedUserData.add(data)
        }
        tableView.reloadData()
        self.setTableHeaderView()
    }
    
    func setTableHeaderView() {
        let headerView:GroupContactsHeaderView = tblVContacts.tableHeaderView as! GroupContactsHeaderView
        if selectedUserData.count == 0 {
            headerView.txtVContacts.text = "Whom would you like to message?"
            headerView.txtVContacts.textColor = UIColor.gray
        } else {
            let strContacts:NSMutableArray! = NSMutableArray()
            for user in selectedUserData {
                strContacts.add(Utils.formatUserName(user as! RPC.UserObject))
            }
            headerView.txtVContacts.text = strContacts.componentsJoined(by: ", ")
            headerView.txtVContacts.textColor = UIColor.darkGray
        }
    }
}
