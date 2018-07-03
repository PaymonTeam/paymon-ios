//
//  ConnectionManager.swift
//  Trado
//
//  Created by Ankit Jayaswal on 08/06/18.
//  Copyright © 2018 Ranosys. All rights reserved.
//

import UIKit

class ConnectionManager: NSObject {

    static let instance = ConnectionManager()
    
    // MARK: - Home Module API Services
    
    /**
     This is request to HomeService to get Home Screen Data
     
     - parameter success: success response
     - parameter failure: failure response
     */
    func getRates(success: @escaping ((_ response: AnyObject?) -> Void), failure: @escaping ((_ error: NSError?) -> Void)) {
        EthernService().getRates(success: success, failure: failure)
    }
}
