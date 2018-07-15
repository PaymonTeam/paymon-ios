import UIKit

class ContactsTableViewCell : UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var photo: ObservableImageView!
}

extension UISearchBar {
    public var textField: UITextField? {
        let subViews = subviews.flatMap { $0.subviews }
        guard let textField = (subViews.filter { $0 is UITextField }).first as? UITextField else {
            return nil
        }
        return textField
    }

    public var activityIndicator: UIActivityIndicatorView? {
        return textField?.leftView?.subviews.flatMap{ $0 as? UIActivityIndicatorView }.first
    }

    var isLoading: Bool {
        get {
            return activityIndicator != nil
        } set {
            if newValue {
                if activityIndicator == nil {
                    let newActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                    newActivityIndicator.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    newActivityIndicator.startAnimating()
                    newActivityIndicator.backgroundColor = UIColor.white
                    textField?.leftView?.addSubview(newActivityIndicator)
                    let leftViewSize = textField?.leftView?.frame.size ?? CGSize.zero
                    newActivityIndicator.center = CGPoint(x: leftViewSize.width/2, y: leftViewSize.height/2)
                }
            } else {
                activityIndicator?.removeFromSuperview()
            }
        }
    }
}

class ContactsViewController : UITableViewController, UISearchBarDelegate {
    let timerQueue = Queue()
    var searchTimer:PMTimer!
    var searchBar:UISearchBar!
    var searchData:[RPC.UserObject] = []
//    var activityView:UIActivityIndicatorView!

    @IBOutlet weak var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        createSearchBar()
        searchTimer = PMTimer(timeout: 0, repeat: false, completionFunction: {
            self.onSearch(self.searchBar.text ?? "")
        }, queue:timerQueue.nativeQueue())
//        navigationBar.autoSetDimension(.height, toSize: 64)
    }

    func createSearchBar() {
        tableView.dataSource = self
        searchBar = UISearchBar()
//        searchBar.showsCancelButton = false
        searchBar.placeholder = "Enter username or login".localized
        searchBar.delegate = self
        searchBar.isLoading = false
//        activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//        activityView.center = self.view.center
//        let view1 = searchBar.
//        activityView.center = CGPoint(x: view1.bounds.origin.x + view1.bounds.size.width/2,
//                y: view1.bounds.origin.y + view1.bounds.size.height/2)
//        view1.addSubview(activityView) //. addSubview:self.activityIndicatorView

//        self.view.addSubview(activityView)

        self.navigationItem.titleView = searchBar
    }

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100
//    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.endEditing(true)

        let row = indexPath.row
        let data = searchData[row]
        tableView.deselectRow(at: indexPath, animated: true)
        let addFriend = RPC.PM_addFriend()
        let userID = data.id!
        addFriend.uid = userID
        NetworkManager.instance.sendPacket(addFriend) { p, e in
            let manager = MessageManager.instance
            if let searchUser = manager.searchUsers[userID] {
                manager.putUser(searchUser)
                if manager.userContacts[userID] == nil {
                    manager.userContacts[userID] = searchUser
                }
            }

            if manager.dialogMessages[userID] == nil {
                manager.dialogMessages = SharedDictionary<Int32, SharedArray<RPC.Message>>()
            }

            let chatView = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            chatView.setValue(Utils.formatUserName(data), forKey: "title")
            chatView.isGroup = false
            chatView.chatID = userID
            DispatchQueue.main.async {
                self.present(chatView, animated: true)
            }
        }
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        super.scrollViewWillBeginDragging(scrollView)
        searchBar.endEditing(true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchData.count
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let data = searchData[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell") as! ContactsTableViewCell
        cell.name.text = Utils.formatUserName(data)
        cell.photo.setPhoto(ownerID: data.id, photoID: data.photoID)
        return cell
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer.reset(withTimeout: 0.3)
    }

    func onSearch(_ text: String) {
        print("SEARCH \(text)")
        let query = text.ltrim([" ", "@"]).rtrim([" "])
        if query.isEmpty {
            searchData.removeAll()
            tableView.reloadData()
            return
        }

        DispatchQueue.main.async {
            self.searchBar.isLoading = true
        }

        let searchContact = RPC.PM_searchContact()
        searchContact.query = query
        NetworkManager.instance.sendPacket(searchContact) { packet, error in
            if let usersPacket = packet as? RPC.PM_users {
                for u:RPC.UserObject! in usersPacket.users {
                    MessageManager.instance.putSearchUser(u)
                    let pid = MediaManager.instance.userProfilePhotoIDs[u.id] ?? 0
                    u.photoID = pid
                }
                self.searchData = usersPacket.users
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else if let e = error as? RPC.PM_error {
                print(e.message)
            }
            DispatchQueue.main.async {
                self.searchBar.isLoading = false
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        onSearch(searchBar.text ?? "")
    }

    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        print("Results")
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Scope button")
    }
}
