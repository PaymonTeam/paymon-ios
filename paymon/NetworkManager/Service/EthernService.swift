//
//  ChatService.swift
//  Trado
//
//  Created by Jogendar Singh on 25/06/18.
//  Copyright © 2018 Ranosys. All rights reserved.
//

import UIKit
import Alamofire

class EthernService: BaseService {

    func getRates(success: @escaping ((_ response: AnyObject?) -> Void), failure: @escaping ((_ error: NSError?) -> Void)) {
        var alamoRequest = AlamofireRequestModal()
        alamoRequest.path = API.Path.rates
        alamoRequest.method = .get
        let dict = [
            "fsyms": "ETH",
            "tsyms": Wallet.supportedCurrencies.joined(separator: ",")
        ]
        alamoRequest.parameters = dict as [String : AnyObject]
        alamoRequest.encoding = URLEncoding() as ParameterEncoding
        callWebServiceAlamofire(alamoRequest, success: success, failure: failure)
    }
}
