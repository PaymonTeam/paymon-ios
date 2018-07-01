//
//  BaseService.swift
//  Trado
//
//  Created by Ankit Jayaswal on 08/06/18.
//  Copyright © 2018 Ranosys. All rights reserved.
//

import UIKit
import Alamofire

struct AlamofireRequestModal {
    var method: Alamofire.HTTPMethod
    var path: String
    var parameters: [String: AnyObject]?
    var encoding: ParameterEncoding
    var headers: [String: String]?
    
    init() {
        method = .post
        path = ""
        parameters = nil
        encoding = JSONEncoding() as ParameterEncoding
        headers = ["Accept-Language": "en",
                    "Accept": "application/json"]
    }
    
    func apiURL() -> String {
        return API.baseURL + self.path
    }

}

class BaseService: NSObject {
    let network = NetworkReachabilityManager.init(host: "https://www.google.com")
    
    func callWebServiceAlamofire(_ alamoReq: AlamofireRequestModal,
                                 success:@escaping ((_ responseObject: AnyObject?) -> Void),
                                 failure:@escaping ((_ error: NSError?) -> Void)) {
        
        guard (network?.isReachable)! else { debugPrint("\n No Network Connection"); return failure(nil) }
        self.printAPIRequest(request: alamoReq)
        
        // preparing api request
        let request = Alamofire.request(alamoReq.apiURL(), method: alamoReq.method, parameters: alamoReq.parameters, encoding: alamoReq.encoding, headers: alamoReq.headers)
        
        // getting response: call response handler method of alamofire
        request.responseJSON(completionHandler: { response in
            self.handleReceivedInfo(response, success: success, failure: failure)
        })
    }

    
    func handleReceivedInfo(_ receivedInfo: DataResponse<Any>,
                            success:@escaping ((_ responseObject: AnyObject?) -> Void),
                            failure:@escaping ((_ error: NSError?) -> Void)) {
        
        let statusCode = receivedInfo.response?.statusCode ?? (receivedInfo.result.error as NSError?)?.code ?? 0
        guard let data = receivedInfo.data else {
            failure(generateError(code: statusCode, errors: nil, message: nil))
            return
        }
        
        let responseObj = try? JSONSerialization.jsonObject(with: data, options: [])
        print("API Response | Code: \(statusCode) \nAPI Response | Data: \(String(describing: responseObj))")
        guard let responseData = responseObj else {
            failure(generateError(code: statusCode, errors: nil, message: nil))
            return
        }
        
        // Check if responseData is [String: Any] or [Any]
        // Continue, if it is of type [String: Any]
        // Or, return in case of [Any], boolean, string etc
        guard let response = responseData as? [String: Any] else {
            success(responseData as AnyObject)
            return
        }
        
        // Check failure cases
        // 1. "errors" is [String: Any]
        // 2. "success": false
        
        if let error = response["errors"] as? [String: Any] {
            failure(generateError(code: statusCode, errors: error, message: nil))
        } else if let result = response["success"] as? Int, result == 0 {
            failure(generateError(code: statusCode, errors: nil, message: response["message"] as? String))
        } else {
            success(response as AnyObject)
        }
        
    }
    
    func generateError(code: Int, errors: [String: Any]?, message: String?) -> NSError {
        var errorMessage = ""
        if let error = errors, let value = error.first?.value {
            switch value {
            case is String:
                errorMessage = value as? String ?? ""
            case is [String]:
                errorMessage = (value as? [String])?.first ?? ""
            default:
                break
            }
            
        } else if let msg = message {
            errorMessage = msg
            
        } else {
            switch code {
            case 500:
                errorMessage = "Server Error(500) \nSomething went wrong. Please try again!"
            case -1010 ..< -1000:
                errorMessage = "We are unable to connect you with the server. Please check your internet connection and try again!"
            default:
                break
            }
        }
        
        return NSError.init(domain: "Error", code: code, userInfo: ["message": errorMessage])
    }
}

extension BaseService {
    
    func printAPIRequest(request: AlamofireRequestModal) {
        print("API Details:")
        print("\(request.method) \(request.path)")
        print("\(String(describing: request.headers))")
        print("\(String(describing: request.parameters))")
    }
    
}
