//
// Created by Vladislav on 22/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit
import PureLayout

class ChatsTableViewOld: UITableView, UITableViewDataSource, UITableViewDelegate {
    class CellData {
        var title:String
        var lastMessageText:String?
        var lastMessageTimeText:String?
        var peer:RPC.Peer
        var photoID:Int64

        init(title:String, peer:RPC.Peer, photoID:Int64) {
            self.title = title;
            self.peer = peer;
            self.photoID = photoID;
        }
    }

    class ViewCell : UITableViewCell {
        var titleView:UILabel!
        var textView:UILabel!
        var shouldSetupConstraints = true

        public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        public init(title:String, lastMsg:String, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)

            titleView = UILabel(frame: CGRect.zero)
            titleView.autoSetDimension(.height, toSize: 20)
//            titleView.autoSetDimension(.width, toSize: 40)
            titleView.text = title

            textView = UILabel(frame: CGRect.zero)
            textView.autoSetDimension(.height, toSize: 20)
//            textView.autoSetDimension(.width, toSize: 40)
            textView.text = lastMsg

            addSubview(titleView)
            addSubview(textView)
        }

        override func updateConstraints() {
            if(shouldSetupConstraints) {
                titleView.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
                titleView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
                textView.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
                textView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
//                textView.autoPinEdge(.top, to: .bottom, of: titleView, withOffset: 0)

                shouldSetupConstraints = false
            }
            super.updateConstraints()
        }

    }

    public var list:SharedArray<CellData>?

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        self.dataSource = self
        self.delegate = self
//        self.backgroundColor = UIColor.gray

        self.reloadData()
        self.reloadInputViews()
        self.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell-chats")
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if list == nil {
            return ViewCell(style: .default, reuseIdentifier: nil)
        }
        let title = list![indexPath.row].title

        var cell:ViewCell?
        if let c = tableView.dequeueReusableCell(withIdentifier: "chatCell-\(title)") {
            cell = c as? ViewCell
        } else {
            cell = ViewCell(title: title, lastMsg: "", reuseIdentifier: "chatCell-\(title)")
        }

//        cell!.textLabel!.text = title
        return cell!
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Opening chat \(list![indexPath.row].title)")
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}
