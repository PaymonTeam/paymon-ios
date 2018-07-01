//
// Created by Vladislav on 01/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import UserNotifications

class GroupChatMessageRcvViewCell : ChatMessageRcvViewCell {
    @IBOutlet weak var photo: ObservableImageView!
    @IBOutlet weak var lblName: UILabel!
}
//import PureLayout

extension String {

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSFontAttributeName: font]
        let size = self.size(attributes: fontAttributes)
        return size.width
    }

    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSFontAttributeName: font]
        let size = self.size(attributes: fontAttributes)
        return size.height
    }
}

class ChatViewController: UIViewController, NotificationManagerListener {


    @IBOutlet weak var messageTextView: UITextView!

    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contraintViewBottom: NSLayoutConstraint!
    //    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupIconImageView: ObservableImageView!
    @IBOutlet weak var lblParticipants: UILabel!
    
    @IBOutlet weak var lblTitle: UILabel!
    var messages: [Int64] = [] //RPC.Message?
    var chatID: Int32!
    var isGroup: Bool!
    var users = SharedArray<RPC.UserObject>()
    var oldFrame : CGRect!

    @IBAction private func onNavBarItemRightClicked() {
        dismiss(animated: true)
    }

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    @IBAction func onSendClicked() {
        if let text = messageTextView.text {
            if text.ltrim([" "]).rtrim([" "]).isEmpty {
                return
            }
            let mid = MessageManager.generateMessageID()
            let message = RPC.PM_message()
            message.itemID = 0
            message.itemType = .NONE
            message.from_id = User.currentUser!.id
            if isGroup {
                message.to_id = RPC.PM_peerGroup()
                message.to_id.group_id = chatID
            } else {
                message.to_id = RPC.PM_peerUser()
                message.to_id.user_id = chatID
            }
            message.id = mid
            message.text = text
            message.date = Int32(Utils.currentTimeMillis() / 1000 + TimeZone.autoupdatingCurrent.secondsFromGMT())

            NetworkManager.instance.sendPacket(message) { p, e in
                if let update = p as? RPC.PM_updateMessageID {
                    for i in 0..<self.messages.count {
                        if self.messages[i] == update.oldID {
                            self.messages.remove(at: i)
                            break
                        }
                    }
                    DispatchQueue.global().sync {
                        self.messages.append(update.newID)
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }

            DispatchQueue.global().sync {
                messages.append(mid)
            }
            
            MessageManager.instance.putMessage(message, serverTime: false)
//        tableView.reloadData()
            let index = IndexPath(row: messages.count > 0 ? messages.count - 1 : 0, section: 0)
            tableView.insertRows(at: [index], with: .bottom)
            tableView.scrollToRow(at: index, at: .bottom, animated: false)

            messageTextView.text = ""
            messageTextView.frame = oldFrame
            messageViewHeight.constant = 44
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // кура
        NotificationManager.instance.addObserver(self, id: NotificationManager.chatAddMessages)
        NotificationManager.instance.addObserver(self, id: NotificationManager.didReceivedNewMessages)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        if isGroup {
            users = MessageManager.instance.groupsUsers.value(forKey: chatID)!
        }
        messageTextView.layer.cornerRadius = 15
        messageTextView.layer.borderWidth = 1;
        messageTextView.layer.borderColor = UIColor(r: 235, g: 235, b: 241).cgColor
        messageTextView.text = "To write a message".localized
        messageTextView.textColor = UIColor.lightGray

        let fixedWidth = messageTextView.frame.size.width
        messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = messageTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height - 2)
        messageTextView.frame = newFrame
        oldFrame = newFrame
        
        lblTitle.text = value(forKey: "title") as? String
        sendButton.addTarget(self, action: #selector(onSendClicked), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140

        messageTextView.delegate = self
        let getChatMessages = RPC.PM_getChatMessages()
        getChatMessages.count = 20
        if isGroup {
            let peerGroup = RPC.PM_peerGroup()
            peerGroup.group_id = chatID;
            getChatMessages.chatID = peerGroup
            lblParticipants.text = "Participants: " + String(users.count)
            let group:RPC.Group! = MessageManager.instance.groups[chatID]!
            groupIconImageView.setPhoto(ownerID: group.id, photoID: group.photo.id)
        } else {
            let peerUser = RPC.PM_peerUser()
            peerUser.user_id = chatID;
            getChatMessages.chatID = peerUser
            groupIconImageView.isHidden = true
        }
        getChatMessages.offset = 0
        MessageManager.instance.loadMessages(chatID: chatID, count: 20, offset: 0, isGroup: isGroup)

    }


    @objc func handleKeyboardNotification(notification: NSNotification) {

        if let userInfo = notification.userInfo {
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
//            print(keyboardFrame)

            let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow

            contraintViewBottom.constant = isKeyboardShowing ? keyboardFrame!.height : 0

            UIView.animate(withDuration: 0,
                    delay: 0,
                    options: UIViewAnimationOptions.curveEaseOut,
                    animations: {
                        self.view.layoutIfNeeded()
                    }, completion: {
                (completed) in

                if isKeyboardShowing {
                    if self.messages.count >= 1 {
                        self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                    }
                }
            })
        }
    }

    func didReceivedNotification(_ id: Int, _ args: [Any]) {
        if id == NotificationManager.chatAddMessages {
            if args.count == 2 {
                if args[1] is Bool {
                    if let messagesToAdd = args[0] as? [Int64] {
                        
                        DispatchQueue.global().sync {
                            messages.append(contentsOf: messagesToAdd)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()

                        if self.messages.count > 0 {
                            let index = IndexPath(row: self.messages.count - 1, section: 0)
                            self.tableView.scrollToRow(at: index, at: .bottom, animated: false)
                        }
                    }
                }
            }
        } else if id == NotificationManager.didReceivedNewMessages {
            if args.count == 1 {
                if let messagesToAdd = args[0] as? [RPC.Message] {
                    messagesToAdd.forEach({ msg in
                        
                        DispatchQueue.global().sync {
                            self.messages.append(msg.id)
                        }

                    })
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()

                    if self.messages.count > 0 {
                        let index = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: index, at: .bottom, animated: false)
                    }
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let fixedWidth = messageTextView.frame.size.width
        messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = messageTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        messageTextView.frame = newFrame

    }

    @IBAction func btnSettingAction(_ sender: Any) {
        self.goToSetting()
    }
    @IBAction func btnBackTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationManager.instance.removeObserver(self, id: NotificationManager.chatAddMessages)
        NotificationManager.instance.removeObserver(self, id: NotificationManager.didReceivedNewMessages)
        NotificationCenter.default.removeObserver(self)
    }
    
    func goToSetting() {
        let groupSettingView = storyboard?.instantiateViewController(withIdentifier: "GroupSettingViewController") as! GroupSettingViewController
        groupSettingView.chatID = chatID
        present(groupSettingView, animated: false, completion: nil)
    }
}

extension ChatViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    

//    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let row = indexPath.row
//        let mid = messages[row]
//        if let message = MessageManager.instance.messages[mid] {
//            if let itemType = message.itemType {
//                switch itemType {
//                case .NONE, .ACTION, .AUDIO, .DOCUMENT, .PHOTO:
//                    return 45.0
//                case .STICKER:
//                    return 120.0
//                }
//            } else {
//                return 45.0
//            }
//        } else {
//            return 0.0
//        }
//    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let mid = messages[row]
        if let message = MessageManager.instance.messages[mid] {
            if message.from_id == User.currentUser!.id {
                if message.itemType == nil || message.itemType == .NONE {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageViewCell") as! ChatMessageViewCell
//                    cell.timeLabel.text = String(message.date)
                    cell.messageLabel.text = message.text
                    cell.messageLabel.sizeToFit()
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageItemViewCell") as! ChatMessageItemViewCell
                    cell.stickerImage.setSticker(itemType: message.itemType, itemID: message.itemID)
                    return cell
                }
            } else {
                if isGroup {
                    if message.itemType == nil || message.itemType == .NONE {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChatMessageRcvViewCell") as! GroupChatMessageRcvViewCell
                        cell.messageLabel.text = message.text
                        cell.messageLabel.sizeToFit()
                        cell.photo.setPhoto(ownerID: message.from_id, photoID: MediaManager.instance.userProfilePhotoIDs[message.from_id]!)
                        let user = MessageManager.instance.users[message.from_id]
                        cell.lblName.text = Utils.formatUserName(user!)
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageItemRcvViewCell") as! ChatMessageItemRcvViewCell
                        cell.stickerImage.setSticker(itemType: message.itemType, itemID: message.itemID)
                        return cell
                    }
                } else {
                    if message.itemType == nil || message.itemType == .NONE {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageRcvViewCell") as! ChatMessageRcvViewCell
                        //                    cell.timeLabel.text = String(message.date)
                        cell.messageLabel.text = message.text
                        cell.messageLabel.sizeToFit()
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageItemRcvViewCell") as! ChatMessageItemRcvViewCell
                        cell.stickerImage.setSticker(itemType: message.itemType, itemID: message.itemID)
                        return cell
                    }
                }
                
            }
        }

        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }

}

extension ChatViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        messageTextView.endEditing(true)

    }
}

extension ChatViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            DispatchQueue.main.async {
                self.onSendClicked()
//                textField.resignFirstResponder()
            }
            return false
        }
        return true
    }

    func resizeTextView(_ textView: UITextView){

//        let textViewFixedWidth: CGFloat = textView.frame.size.width
//        let newSize: CGSize = textView.sizeThatFits(CGSize(width: textViewFixedWidth, height: CGFloat(MAXFLOAT)))
//        var newFrame: CGRect = textView.frame
//
//        var textViewYPosition = textView.frame.origin.y
//        var heightDifference = textView.frame.height - newSize.height
//
//        if (abs(heightDifference) > 20) {
//            newFrame.size = CGSize(width: fmax(newSize.width, textViewFixedWidth), height: newSize.height)
//            newFrame.offsetBy(dx: 0.0, dy: 0)
//        }
//        textView.frame = newFrame

        let fixedWidth = textView.frame.size.width
//        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height - 2)
        textView.frame = newFrame
//        textView.isScrollEnabled

        UIView.animate(withDuration: 0,
                delay: 0,
                options: UIViewAnimationOptions.curveEaseOut,
                animations: {
                    self.view.layoutIfNeeded()
                }, completion: {
            (completed) in

        })

        if newFrame.height > oldFrame.height {
            let resizeFrame = newFrame.height - oldFrame.height
            oldFrame = newFrame
//            print(resizeFrame)
            messageViewHeight.constant += resizeFrame

        } else if oldFrame.height > newFrame.height {

            let resizeFrame = oldFrame.height - newFrame.height
            oldFrame = newFrame
            messageViewHeight.constant -= resizeFrame
            UIView.animate(withDuration: 0,
                    delay: 0,
                    options: UIViewAnimationOptions.curveEaseOut,
                    animations: {
                        self.view.layoutIfNeeded()
                    }, completion: {
                (completed) in

            })
        }

//        print(textView.frame.height)
    }
    func textViewDidChange(_ textView: UITextView) {
        resizeTextView(textView)

        if textView.text == "" {
            textView.frame = oldFrame
            messageViewHeight.constant = 44
        }

//        if messageViewHeight.constant < messageTextViewHeight.constant {
//            messageViewHeight.constant += messageTextViewHeight.constant
//        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        resizeTextView(textView)

        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor(r: 32, g: 32, b: 32)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "To write a message".localized
            textView.textColor = UIColor.lightGray

            if textView.text == "" {
                textView.frame = oldFrame
                messageViewHeight.constant = 44
            }
        }

        resizeTextView(textView)
    }
}
