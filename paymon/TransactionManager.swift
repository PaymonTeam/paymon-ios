////
//// Created by Vladislav on 20/09/2017.
//// Copyright (c) 2017 Paymon. All rights reserved.
////

import Foundation

class TransactionManager: NSObject, UIAlertViewDelegate {
    public static let instance = TransactionManager()

    private var API_LINK: String
    private var API_VERSION: String
    public static var PAYEER_REGEX = "^P\\d{7,8}$"
    private let EMAIL = "transactions@paymon.ru"
    public let DEFAULT_TX_FEE = 100000;

    public var apiAKey: String?
    public var nonce: Int64
    var request: BRPaymentProtocolRequest!
    let queue = Queue(name: "transactionManagerQueue")!
//    var ymBalance:Double?

    static let TM_TX_FEE_PER_KB: UInt64 = 1000     // standard tx fee per kb of tx size, rounded up to nearest kb
    static let TM_TX_OUTPUT_SIZE: UInt64 = 34          // estimated size for a typical transaction output
    static let TM_TX_INPUT_SIZE: UInt64 = 148         // estimated size for a typical compact pubkey transaction input
    static let TM_TX_MIN_OUTPUT_AMOUNT = (TransactionManager.TM_TX_FEE_PER_KB * UInt64(3) * (TransactionManager.TM_TX_OUTPUT_SIZE + TransactionManager.TM_TX_INPUT_SIZE) / UInt64(1000)) //no txout can be below this amount
    static let TM_TX_MAX_SIZE = 100000      // no tx can be larger than this size in bytes
    static let TM_TX_FREE_MAX_SIZE = 1000        // tx must not be larger than this size in bytes without a fee
    static let TM_TX_FREE_MIN_PRIORITY: UInt64 = 57600000 // tx must not have a priority below this value without a fee
    static let TM_TX_UNCONFIRMED = INT32_MAX   // block height indicating transaction is unconfirmed
    static let TM_TX_MAX_LOCK_HEIGHT = 500000000   // a lockTime below this value is a block height, otherwise a timestamp
    let YM_CLIENT_ID = "0451EEB70AB21E9752C66F5BFB07B7C9948B53D4D7BBFDEB83DC4CC2E12B220E";
    let YM_REDIRECT_URI = "https://paymon.ru/yandex_money_api_key.php";
    let YM_OAUTH2_CLIENT_SECRET = "C96B238DCEA5C83C93AA0AE2C39474DD7144E2579E7F8D663DF31B46FDE3F14608AFC46EDB52287FB237C821DAE304D2E5F96B8E65C12E4CEC8B5FE37244B717";
    let YM_EMAIL = "transactions@paymon.ru";

    public enum PaymentMethod: Int32 {
        case YANDEX_MONEY = 15,
             RUR = 8,
             BTC = 12,
             ETH = 42,
             PAYEER_USD = 22,
             PAYEER_RUB = 41,
             PAYEER_EUR = 50
    }

    private override init() {
        API_LINK = "https://prostocash.com/api/"
        API_VERSION = "1"
        nonce = Utils.currentTimeMillis() % 4294967295;
        super.init()
        getApiKey() { s in
            self.apiAKey = s
        }
    }

    func addPercentEscapesForString(_ string:String) -> String {
//        if (NSFoundationVersionNumber <= iOS_VersionNumber_8_4) {
//            return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
//                    (__bridge CFStringRef)string,
//            NULL,
//            ";/?:@&=+$," as CFStringRef,
//            kCFStringEncodingUTF8));
//        }
//        if NSFoundationVersionNumber <= iOS_VersionNumber_8_4 {
//        return NSString.stringByAddingPercentEncodingWithAllowedCharacters()
        return string.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: ";/?:@&=+$,"))! //.urlHostAllowed)
//        return CFURLCreateStringByAddingPercentEscapes(nil, (string as? CFString), nil, (";/?:@&=+$," as? CFString), UInt32(String.Encoding.utf8.rawValue) as CFStringEncoding) as! String
//        } else {
//            return "ERR"
//        }
    }

    public func initYM(webView:UIWebView) {
        let request = NSMutableURLRequest(url: URL(string: "https://money.yandex.ru/oauth/authorize")!)

        let post = NSMutableString(capacity: 0)
        post.append("\(addPercentEscapesForString("client_id"))=\(addPercentEscapesForString("\(YM_CLIENT_ID)"))&")
        post.append("\(addPercentEscapesForString("response_type"))=\(addPercentEscapesForString("code"))&")
        post.append("\(addPercentEscapesForString("redirect_uri"))=\(addPercentEscapesForString("\(YM_REDIRECT_URI)"))&")
        post.append("\(addPercentEscapesForString("scope"))=\(addPercentEscapesForString("payment-p2p account-info"))")

        let postData = post.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)!
//        print(post)
        request.httpMethod = "POST"
        request.setValue("\(UInt64(postData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
//        print(postData)
//        print(request)
        let authorizationRequest: URLRequest? = request as URLRequest
        webView.loadRequest(authorizationRequest!)
    }

    public func requestPayment(to:String, amount:Decimal, callback:@escaping (String?)->()) {
        if User.ymAccessToken == nil {
            callback(nil)
            return
        }

        let post = NSMutableString(capacity: 0)
        post.append("\(addPercentEscapesForString("pattern_id"))=\(addPercentEscapesForString("p2p"))&")
        post.append("\(addPercentEscapesForString("to"))=\(addPercentEscapesForString(to))&")
        post.append("\(addPercentEscapesForString("amount_due"))=\(addPercentEscapesForString("\(amount)"))&")
        post.append("\(addPercentEscapesForString("comment"))=\(addPercentEscapesForString("Пополнение через Paymon"))")
        let postData = post.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)!

        var request = URLRequest(
                url: URL(string: "https://money.yandex.ru/api/request-payment")!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("\(UInt64(postData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(User.ymAccessToken!)", forHTTPHeaderField: "Authorization")
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
//                print(data)
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? JSONObject {
                        if let status = dictionary["status"] as? String, status == "success" {
//                            print("request successed")

                            let rid = dictionary["request_id"] as? String

                            self.queue.run({
                                callback(rid)
                            })
                            return
                        }
                    }
                } catch {
                    print(error)
                }
            }
            callback(nil)
        }
        task.resume()
    }

    public func processPayment(request_id:String, callback:@escaping (JSONObject?)->()) {
        if User.ymAccessToken == nil {
            callback(nil)
            return
        }

        let post = NSMutableString(capacity: 0)
        post.append("\(addPercentEscapesForString("request_id"))=\(addPercentEscapesForString(request_id))")
        let postData = post.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)!

        var request = URLRequest(
                url: URL(string: "https://money.yandex.ru/api/process-payment")!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("\(UInt64(postData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(User.ymAccessToken!)", forHTTPHeaderField: "Authorization")
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
//                print(data)
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? JSONObject {
                        if let status = dictionary["status"] as? String, status == "success" {
//                            print("process succeeded")
                            self.queue.run({
                                callback(dictionary)
                            })
                            return
                        }
                    }
                } catch {
                    print(error)
                }
            }
            callback(nil)
        }
        task.resume()

        return
    }

    public func getYMAccointInfo(callback:@escaping (Double?, String?)->()) {
        if User.ymAccessToken == nil {
            callback(nil, nil)
            return
        }

        var request = URLRequest(
                url: URL(string: "https://money.yandex.ru/api/account-info")!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(User.ymAccessToken!)", forHTTPHeaderField: "Authorization")

//        var balance:Double? = nil
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                print(data)
                do {
                    print(String(data: data, encoding: .utf8)!)
                    if let dictionary = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments]) as? JSONObject {
                        if let b = dictionary["balance"] as? Double,
                           let addr = dictionary["account"] as? String {
                            callback(b, addr)
                            return
                        }
                    }
                } catch {
//                    print("JSON ERR")
                    print(error)
                    callback(0.0, nil)
//                    balance = 0.0
                }
            }
            callback(0.0, nil)
//            balance = 0.0
        }
        task.resume()
//        while balance == nil {}
//        return balance
    }

    public func getYMAccessToken(webView:UIWebView, code:String) -> String {
        //Authorization: Bearer <access_token>
        //https://money.yandex.ru/api/
        //account-info
        let post = NSMutableString(capacity: 0)
        post.append("\(addPercentEscapesForString("code"))=\(addPercentEscapesForString("\(code)"))&")
        post.append("\(addPercentEscapesForString("client_id"))=\(addPercentEscapesForString("\(YM_CLIENT_ID)"))&")
        post.append("\(addPercentEscapesForString("grant_type"))=\(addPercentEscapesForString("authorization_code"))&")
        post.append("\(addPercentEscapesForString("redirect_uri"))=\(addPercentEscapesForString("\(YM_REDIRECT_URI)"))&")
        post.append("\(addPercentEscapesForString("client_secret"))=\(addPercentEscapesForString("\(YM_OAUTH2_CLIENT_SECRET)"))")

        let postData = post.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)!

        var request = URLRequest(
                url: URL(string: "https://money.yandex.ru/oauth/token")!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("\(UInt64(postData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData

        var token = ""
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: data) as? JSONObject {
                        if let at = dictionary["access_token"] as? String {
                            token = at
                            print("token=\(token)")
                            User.ymAccessToken = token

                            return
                        }
                    }
                } catch {
                    print(error)
                    token = "error"
                }
            }
            token = "error"
        }
        task.resume()
        while token.isEmpty {}
        return token
    }

    public func getApiKey(callback: @escaping (String?)->()) {
        if (apiAKey == nil) {
            if let prefs = UserDefaults(suiteName: "pref_api") {
                if let apiAKey = prefs.string(forKey: "pref_key") {
                    callback(apiAKey)
                    return
                } else {
                    requestPOST(method: "app-register") { json in
                        if let jsonResponse = json {
                            do {
                                if let akey = try (jsonResponse ~ "value" ~ "Access")["akey"] as? String {
                                    if let rkey = try (jsonResponse ~ "value" ~ "Rules")["rkey"] as? String {
                                        self.nonce += 1
                                        self.requestPOST(
                                                method: "accept-rules",
                                                withParams: ["nonce": self.nonce, "akey": akey, "rkey": rkey, "value": "yes"]) { json in
                                            if json != nil {
                                                prefs.set(akey, forKey: "pref_key")
                                                self.apiAKey = akey;
                                            }
                                        }
                                    }
                                }
                            } catch {
                                print("Error parsing JSON")
                                callback(nil)
                                return
                            }
                            self.nonce += 1
                        }
                    }
                }
            }
        }
        callback(apiAKey)
    }

    /**
     * Отправляет пост запрос
     * @param method Название метода(без слешей)
     * @param params JSON праметры
     * @return ответ в формате JSON
     * @throws IOException
     */
    public func requestPOST(method: String, withParams: JSONObject, callback: @escaping (JSONObject?)->()) {
        print("requestPOST: method:\(method) params:\(withParams)")
        nonce += 1
        var params = withParams
        if params["nonce"] == nil {
            params["nonce"] = nonce
        }
        if params["akey"] == nil {
            params["akey"] = apiAKey
        }
        let s = "\(API_LINK)\(API_VERSION)/\(method)/"
        var request = URLRequest(
                url: URL(string: s)!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            if let s = String(data: jsonData, encoding: .utf8) {
                print(s)
            } else {
                print("fail")
            }
            let sess = URLSession.shared.uploadTask(with: request, from: jsonData, completionHandler: { data, url, error in
                var ret: String = ""
                if data != nil {
                    if let s1 = String(data: data!, encoding: .utf8) {
                        ret = s1
                        print("Completed \(ret)")
//                        return
                    }
                } else {
                    print("Completed without data")
                }
                if ret == "" {
                    ret = "{\"status\":\"error\"}"
                }

                if let v = ret.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: v) as? JSONObject {
//                        print("RESP: \(dictionary)")
                            callback(dictionary)
                        }
                    } catch {
                        print("JSONPost error \(error)")
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
            })
            sess.resume()
        } catch {
            print("JSONPost error \(error.localizedDescription)")
            callback(nil)
        }
    }

    public func requestPOSTSync(method: String, withParams: JSONObject) -> JSONObject? {
        print("requestPOST: method:\(method) params:\(withParams)")
        nonce += 1
        var params = withParams
        if params["nonce"] == nil {
            params["nonce"] = nonce
        }
        if params["akey"] == nil {
            params["akey"] = apiAKey
        }
        let s = "\(API_LINK)\(API_VERSION)/\(method)/"
        var request = URLRequest(
                url: URL(string: s)!,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            if let s = String(data: jsonData, encoding: .utf8) {
                print(s)
            }
            var ret: String = ""
            let sess = URLSession.shared.uploadTask(with: request, from: jsonData, completionHandler: { data, url, error in
                if data != nil {
                    if let s1 = String(data: data!, encoding: .utf8) {
                        ret = s1
//                        print("Completed \(s1) \(url) \(error)")
                        return
                    }
                } else {
                    print("Completed without data")
                }
                if ret == "" {
                    ret = "{\"status\":\"error\"}"
                }
            })
            while ret == "" { }

            if let v = ret.data(using: .utf8) {
                do {
                    if let dictionary = try JSONSerialization.jsonObject(with: v) as? JSONObject {
//                        print("RESP: \(dictionary)")
                        return dictionary
                    }
                } catch {
                    print(error)
                    return nil
                }
            } else {
                return nil
            }

            sess.resume()
        } catch {
            print(error.localizedDescription)
            return nil
        }
        return nil
    }

    public func requestPOST(method: String, callback: @escaping (JSONObject?)->()) {
        self.requestPOST(method: method, withParams: [:], callback: callback)
    }

    public func requestPOSTSync(method: String) -> JSONObject? {
        return self.requestPOSTSync(method: method, withParams: [:])
    }

    /**
     * [from, to]
     */
    public func exchangeRateTask(from: PaymentMethod, to: PaymentMethod, callback: @escaping ((Decimal?, Decimal?, Int?, Int?)->())) {
        var requestParams = JSONObject()
        requestParams["psid1"] = from.rawValue //params.firstPayments
        requestParams["psid2"] = to.rawValue //params.secondPayments
        print("doInBackground: ExchangeRateTask->\(requestParams)")
//        print("doInBackground: ExchangeRateTask<-\(request)")
        requestPOST(method: "exchange-rate", withParams: requestParams) { json in
            if let resp = json {
                if resp["status"] as! String == "success" {
                    do {
                        let valueObject = try resp ~ "value"
                        print("OUT \(valueObject["out"])")
                        print("IN \(valueObject["in"])")

                        var exchangeIn:Decimal = 0
                        var exchangeOut:Decimal = 0

                        if let v = valueObject["in"] as? Double {
                            exchangeIn = Decimal(floatLiteral: v)
                        } else if let v = valueObject["in"] as? String {
                            exchangeIn = Decimal(string: v)!
                        }

                        if let v = valueObject["out"] as? Double {
                            exchangeOut = Decimal(floatLiteral: v)
                        } else if let v = valueObject["out"] as? String {
                            exchangeOut = Decimal(string: v)!
                        }

                        if let minAmount = valueObject["in_min"] as? Int,
                           let maxAmount = valueObject["in_max"] as? Int {
                            callback(exchangeIn, exchangeOut, minAmount, maxAmount)
                        }
                    } catch {
                        print(error)
                        callback(nil, nil, nil, nil)
                    }
                }
            } else {
                callback(nil, nil, nil, nil)
            }
        }
    }

    /**
     * [from, to, howMany, (0 -> / 1 <-)]
     */
    public func ExchangeRateCalculateTask(params:String...) {
        var requestParams = JSONObject()
        requestParams["psid1"] = params
        requestParams["psid2"] = params[1]
        requestParams["amount"] = params[2]
        requestParams["direct"] = params[3]

        requestPOST(method: "exchange-rate-calculate", withParams: requestParams) { json in

        }
    }
/*
/**
 * [from, to, howManyIn, howManyOut, (0 -> / 1 <-), YandexId, email, btcWallet]
 */
public static class OrderCreateYandex extends AsyncTask<String, Object, JSONObject> {

    protected JSONObject doInBackground(String... params) {
        JSONObject requestParams    = JSONObject()
        JSONObject newOrder         = JSONObject()
        do {
            newOrder["psid1"] = params
            newOrder["psid2"] = params[1]
            newOrder["in"] = params[2]
            newOrder["out"] = params[3]
            newOrder["direct"] = params[4]
            newOrder["agreement"] = "yes"
            newOrder["props"] = JSONArray()
                    .put(JSONObject()
                            .put("name" , "from_acc")
                            .put("value", params[5]))
                    .put(JSONObject()
                            .put("name" , "email")
                            .put("value", params[6]))
                    .put(JSONObject()
                            .put("name" , "to_acc")
                            .put("value", params[7])))
            requestParams.put("Order", newOrder)
        } catch {

        }

        var request = nil
        do {
            request = instance.requestPOST("order-create", requestParams)
        } catch {

        }

        return request
    }
}

/**
 * [order_id]
 */
public static class ValidateOrder extends AsyncTask<String, Object, JSONObject> {

    protected JSONObject doInBackground(String... params) {
        var requestParams = JSONObject()
        do {
            requestParams["order_id"] = params
        } catch {

        }

        var request = nil
        do {
            request = instance.requestPOST("order-validate", requestParams)
        } catch {

        }
        return request
    }
}

/**
 * [order_id]
 */
public static class OrderPayInfo extends AsyncTask<String, Object, JSONObject> {

    protected JSONObject doInBackground(String... params) {
        var requestParams = JSONObject()
        do {
            requestParams["order_id"] = params
        } catch {

        }

        var request = nil
        do {
            request = instance.requestPOST("order-pay-info", requestParams)
        } catch {

        }
        return request
    }
}

/**
 * [order_id]
 */
public static class OrderConfirm extends AsyncTask<String, Object, JSONObject> {

    protected JSONObject doInBackground(String... params) {
        var requestParams = JSONObject()
        do {
            requestParams["order_id"] = params
        } catch {

        }

        var request = nil
        do {
            request = instance.requestPOST("order-confirm", requestParams)
        } catch {

        }
        return request
    }
}

public static class YandexMoneyToCrypto extends AsyncTask<YandexMoneyToCryptoStruct, Object, JSONObject> {
    private static let TAG = "YandexMoneyToCrypto"


    protected JSONObject doInBackground(params:YandexMoneyToCryptoStruct ...) {
        //test
//            if (true)
//            return JSONObject()

        //create order
        var requestParams    = JSONObject()
        var newOrder         = JSONObject()
        if params.count != 1 { return nil }
        do {
            newOrder["psid1"]    =   params.getFrom().getID()
            newOrder["psid2"]    =   params.getTo().getID()
            newOrder["in"]       =   params.getHowManyIn()
            newOrder["out"]      =   params.getHowManyOut()
            newOrder["direct"]   =   params.getDirection()
            newOrder["agreement"]=   "yes"
// TODO: test json arr
            newOrder["props"]    =   JSONArray()
                    .put(JSONObject()
                            .put("name" , "from_acc")
                            .put("value", params.getYandexId()))
                    .put(JSONObject()
                            .put("name" , "email")
                            .put("value", params.getEmail()))
                    .put(JSONObject()
                            .put("name" , "to_acc")
                            .put("value", params.getBtcWallet())))
            requestParams.put("Order", newOrder)
        } catch {

        }
        print("doInBackground: order-create(->): " + requestParams)
        var answer = nil
        do {
            answer = instance.requestPOST("order-create", requestParams)
        } catch {

        }
        print("doInBackground: order-create(<-): " + answer)

        do {
            if answer["status"] as? String == "error" {
                return nil
            }
        } catch {
            return nil
        }

        if (answer == nil) return nil
        var orderID = 0
        do {
            orderID = (answer ~ "value")["id"] as Int64
        } catch {

        }
        print("doInBackground: order-id: " + orderID)

        //validate order
        requestParams = JSONObject()
        do {
            requestParams["order_id"] = orderID
        } catch {

        }
        print("doInBackground: order-validate(->): " + requestParams)
        answer = nil
        do {
            answer = instance.requestPOST("order-validate", requestParams)
        } catch {

        }
        print("doInBackground: order-validate(<-): " + answer)

        do {
            if answer["status"] == "error" {
                return nil
            }
        } catch {

            return nil
        }

        //order pay info
        requestParams = JSONObject()
        do {
            requestParams["order_id"] = orderID
        } catch {

        }
        print("doInBackground: order-pay-info(->): " + requestParams)
        answer = nil
        do {
            answer = instance.requestPOST("order-pay-info", requestParams)
        } catch {

        }
        print("doInBackground: order-pay-info(<-): " + answer)

        do {
            if answer.getString("status") == "error" {
                return nil
            }
        } catch {

            return nil
        }

        if (answer == nil) return nil

        var recipientID:String! = nil
        do {
            recipientID = (answer ~ "value" ~ "info")[0]["value"] as? String
        } catch {

        }
        print("doInBackground: recipientID: " + recipientID)
        //request YM
        let paramsForRequestPaymentApiRequest:[String:String] = [:]
        paramsForRequestPaymentApiRequest["to"] = recipientID
        paramsForRequestPaymentApiRequest["amount_due"] = params.howManyIn()
        paramsForRequestPaymentApiRequest["comment"] = "Пополнение BTC через Paymon"
        print("doInBackground: paramsForRequestPaymentApiRequest: " + paramsForRequestPaymentApiRequest)
        var requestPayment = nil
        do {
            requestPayment = YandexMoney.instance.getApiClient().execute(RequestPayment.Request.newInstance("p2p", paramsForRequestPaymentApiRequest))
        } catch {

        }
        print("doInBackground: requestPayment: " + requestPayment)
        // TODO: 29.06.17 комиссия

        //process YM
        if (requestPayment == nil) return nil
        var requestID = requestPayment.requestId
        print("doInBackground: requestId " + requestID)
        var processPayment = nil
        do {
            processPayment = YandexMoney.instance.getApiClient().execute(ProcessPayment.Request(requestID))
        } catch {

            /** order cancel */
            requestParams = JSONObject()
            do {
                requestParams.put("order_id", orderID)
            } catch {

            }
            print("doInBackground: order-cancel(->): " + requestParams)
            answer = nil
            do {
                answer = instance.requestPOST("order-cancel", requestParams)
            } catch {

            }
            print("doInBackground: order-cancel(<-): " + answer)


            return nil
        }
        print("doInBackground: processPayment" + processPayment)
        //order-confirm
        requestParams = JSONObject()
        do {
            requestParams.put("order_id", orderID)
        } catch {

        }
        print("doInBackground: order-confirm(->): " + requestParams)
        answer = nil
        do {
            answer = instance.requestPOST("order-confirm", requestParams)
        } catch {

        }
        print("doInBackground: order-confirm(<-): " + answer)

        if answer["status"] == "error" {
            return nil
        }

        return answer
    }
}

public static class YandexMoneyToCryptoStruct {
    private var from, to:PaymentMethod
    private var howManyIn, howManyOut:Double
    private var direction:Int16
    private var yandexId, email, btcWallet:String

    public init(_ from:PaymentMethod, _ to:PaymentMethod, _ howManyIn:Double,
                                     _ howManyOut:Double, short direction,
                                     _ yandexId:String, _ email:String, _ btcWallet:String) {
        self.from = from
        self.to = to
        self.howManyIn = howManyIn
        self.howManyOut = howManyOut
        self.direction = direction
        self.yandexId = yandexId
        self.email = email
        self.btcWallet = btcWallet
    }
}

public static class CryptoToFiatMoney extends AsyncTask<CryptoToFeatMoneyStruct, Object, Boolean> {
    private static let TAG = "CryptoToFiatMoney"

    protected Boolean doInBackground(CryptoToFeatMoneyStruct... params) {
        var requestParams = JSONObject()
        var newOrder = JSONObject()
        var answer = nil
        if (params.count < 1) {
            return false
        }
        /** create order */
        do {
            newOrder.put("psid1", params.getFrom().getID())
            newOrder.put("psid2", params.getTo().getID())
            var value = (int) (params.getHowManyInSATOSHI()) / 100000000.0f
            var df = DecimalFormat("#")
            df.setMaximumFractionDigits(8)
            var format = df.format(value)
            print("doInBackground: " + format + " " + String.format("%.8f", value))
            newOrder.put("in", String.format(Locale.US, "%.8f", value))
            newOrder.put("out", params.getHowManyOut())
            newOrder.put("direct", params.getDirection())
            newOrder.put("agreement", "yes")
            newOrder.put("props", JSONArray()
                    .put(JSONObject()
                            .put("name", "email")
                            .put("value", params.getEmail()))
                    .put(JSONObject()
                            .put("name", "to_acc")
                            .put("value", params.getYandexId())))
            requestParams.put("Order", newOrder)
        } catch {

        }
        print("doInBackground: order-create(->): " + requestParams)
        answer = nil
        do {
            answer = instance.requestPOST("order-create", requestParams)
        } catch {

        }

        if answer != nil {
            print("doInBackground: order-create(<-): " + answer)
            var orderID = 0
            if oid = (answer~"value")["id"] as? Int64 {
                orderID = oid
            }
            print("doInBackground: orderId: " + orderID)
            /** validate order */
            requestParams = JSONObject()
            do {
                requestParams["order_id"] = orderID
            } catch {

            }
            print("doInBackground: validate-order(->): " + requestParams)
            answer = nil
            do {
                answer = instance.requestPOST("order-validate", requestParams)
            } catch {

            }
            print("doInBackground: validate-order(<-): " + answer)
            /** order pay info */
            requestParams = JSONObject()
            requestParams["order_id"] = orderID
            print("doInBackground: order-pay-info(->): \(requestParams)")
            answer = nil
            do {
                answer = instance.requestPOST("order-pay-info \(requestParams)")
            } catch {
            }
            if answer != nil {
                print("doInBackground: order-pay-info(<-): \(answer)")
                var recipientBTCWallet:String! = nil
                do {
                    recipientBTCWallet = (answer~"value"~"info")[0]["value"] as? String
                } catch {

                }
                /** btc */
                if recipientBTCWallet != nil {
                    print("doInBackground: recipientBTCWallet: \(recipientBTCWallet)")
                    var wallet = params.getWalletApplication().getWallet()
                    Address recipientAddress
                    do {
                        recipientAddress = Address.fromBase58(Constants.NETWORK_PARAMETERS, recipientBTCWallet)
                    } catch {
                        return false
                    }
                    var coin = Coin.valueOf(params.getHowManyInSATOSHI())
                    Transaction transaction
                    do {
                        org.bitcoinj.core.Context.propagate(Constants.CONTEXT)
                        var to = SendRequest.to(recipientAddress, coin)
                        to.feePerKb = Transaction.REFERENCE_DEFAULT_MIN_TX_FEE
                        transaction = wallet.sendCoinsOffline(to)
                        transaction.verify()
                    } catch {

                        /** order cancel */
                        requestParams = JSONObject()
                        do {
                            requestParams.put("order_id \(orderID)")
                        } catch {
                        }
                        print("doInBackground: order-cancel(->): \(requestParams)")
                        answer = nil
                        do {
                            answer = instance.requestPOST("order-cancel \(requestParams)")
                        } catch {
                        }
                        print("doInBackground: order-cancel(<-): \(answer)")
                        return false
                    }

                    /** order confirm */
                    requestParams = JSONObject()
                    do {
                        requestParams["order_id"] = orderID
                    } catch {

                    }
                    print("doInBackground: order-confirm(->): \(requestParams)")
                    answer = nil
                    do {
                        answer = instance.requestPOST("order-confirm \(requestParams)")
                    } catch {

                    }
                    print("doInBackground: order-confirm(<-): \(answer)")
                    return true
                }
            }
        }
        return false
    }
}
public class CryptoToFeatMoneyStruct {
    public var from, to:PaymentMethod
    public var howManyInSATOSHI:Int64
    public var howManyOut:Double
    public var direction:Int16
    public var yandexId, email:String
//    public var walletApplication:WalletApplication
//    public var feeCategory:FeeCategory

    public init(_ from:PaymentMethod, _ to:PaymentMethod, _ howManyInSATOSHI:Int64,
                                   _ howManyOut:Double, _ direction:Int16, _ yandexId:String,
                                   _ email:String, //_ walletApplication:WalletApplication,
                                   //_ feeCategory:FeeCategory
    ) {
        self.from = from
        self.to = to
        self.howManyInSATOSHI = howManyInSATOSHI
        self.howManyOut = howManyOut
        self.direction = direction
        self.yandexId = yandexId
        self.email = email
//        self.walletApplication = walletApplication
//        self.feeCategory = feeCategory
    }
}
*/
    public class PairPayment {
        public var firstPayments:PaymentMethod
        public var secondPayments:PaymentMethod
        public var direct:Int32

        public init(_ firstPayments:PaymentMethod, _ secondPayments:PaymentMethod) {
            self.firstPayments = firstPayments
            self.secondPayments = secondPayments
            direct = 0
        }

        public init(_ firstPayments:PaymentMethod, _ secondPayments:PaymentMethod, _ direct:Int32) {
            self.firstPayments = firstPayments
            self.secondPayments = secondPayments
            self.direct = direct
        }
    }
/*
public static class PayerStruct {
    public var from:PaymentMethod, to:PaymentMethod
    public var howManyIn:Double, howManyOut:Double
    public var direction:Int16
    public var payerIdOrEmail, email, btcWallet, link: String
    public var orderID:Int64

    public init(_ from:PaymentMethod, _ to:PaymentMethod, _ howManyIn:Double, _ howManyOut:Double, _ direction:Int16, _ payerIdOrEmail:String, _ email:String, _ btcWallet:String) {
        self.from = from
        self.to = to
        self.howManyIn = howManyIn
        self.howManyOut = howManyOut
        self.direction = direction
        self.payerIdOrEmail = payerIdOrEmail
        self.email = email
        self.btcWallet = btcWallet
        link = ""
        orderID = 0
    }
}
public static class PayerCreate extends AsyncTask<PayerStruct, Object, PayerStruct> {
    protected PayerStruct doInBackground(PayerStruct... params) {
        let TAG = "PayerCreateAndConfirm->doInBackground"
        var requestParams = JSONObject()
        var newOrder = JSONObject()
        var answer = nil
        if (params.count != 1) return nil
        do {
            /** create order */
            newOrder["psid1"]    =   params.getFrom().getID()
            newOrder["psid2"]    =   params.getTo().getID()
            newOrder["in"]       =   params.getHowManyIn()
            newOrder["out"]      =   params.getHowManyOut()
            newOrder["direct"]   =   params.getDirection()
            newOrder["agreement"]=   "yes"
            newOrder.put("props"    ,   JSONArray()
                    .put(JSONObject()
                            .put("name" , "from_acc")
                            .put("value", params.getPayerIdOrEmail()))
                    .put(JSONObject()
                            .put("name" , "email")
                            .put("value", params.getEmail()))
                    .put(JSONObject()
                            .put("name" , "to_acc")
                            .put("value", params.getBtcWallet())))
            requestParams.put("Order", newOrder)
            print("doInBackground: order-create(->): " + requestParams)
            answer = instance.requestPOST("order-create", requestParams)
            print("doInBackground: order-create(<-): " + answer)
            if (answer == nil) return nil
            params.setOrderID(answer.getJSONObject("value").getLong("id"))
            print("doInBackground: order-id: " + params.getOrderID())
            /** validate order */
            requestParams = JSONObject()
            requestParams["order_id"] = params.getOrderID()
            print("doInBackground: order-validate(->): " + requestParams)
            answer = nil
            answer = instance.requestPOST("order-validate", requestParams)
            print("doInBackground: order-validate(<-): " + answer)
            params.setLink("https://prostocash.com/payeer-send/?id=" + String.valueOf(params.getOrderID()))
            print("doInBackground: end " + params.getLink() + "\n" + params.getOrderID())
        } catch {
        }

        return params
    }
}

//    public enum UNIVERSAL_TASK_STATUS {
//        DONE,
//        ERROR_CREATE_ORDER,
//
//    private var API_LINK:String
//    private var API_VERSION:String
//    public static var PAYEER_REGEX = "^P\\d{7,8}$"
//    private let EMAIL = "transactions@paymon.ru"
//    public let DEFAULT_TX_FEE = 100000;
//
//    public var apiAKey:String?
//    public var nonce:Int64
//    public enum PaymentMethod: Int32 {
//        case YANDEX_MONEY = 15,
//            BTC = 12,
//            ETH = 42,
//            PAYEER_USD = 22,
//            PAYEER_RUB = 41,
//            PAYEER_EUR = 50
//    }
*/

    func doUniversalTask(_ params: TransactionTaskInput, callback: @escaping ((TransactionTaskOutput?) -> ())) {
        queue.run {
            let output = TransactionTaskOutput(false, nil)

            var requestParams = JSONObject()
            var answer = JSONObject()
            var orderID: Int64
            //  create order
            let newOrder: JSONObject = [
                "psid1": params.from.rawValue,
                "psid2": params.to.rawValue,
                "in": params.howManyIn.description,
                "out": params.howManyOut.description,
                "direct": 0,
                "agreement": "yes",
                "props": [
                    ["name": "from_acc",
                     "value": params.addressFrom],
                    ["name": "email",
                     "value": self.EMAIL],
                    ["name": "to_acc",
                     "value": params.addressTo]
                ]
            ]
            requestParams["Order"] = newOrder

            print("doInBackground: order-create -> : \(requestParams)")
            if let resp = self.requestPOSTSync(method: "order-create", withParams: requestParams) {
                answer = resp
            } else {
                callback(output)
                return
            }

            print("doInBackground: order-create <- : \(answer)")
            if let answer = answer["status"] as? String {
                if answer == "error" {
                    callback(output)
                    return
                }
            } else {
                callback(output)
                return
            }
            do {
                if let oid = try (answer ~ "value")["id"] as? Int64 {
                    orderID = oid
                } else {
                    callback(output)
                    return
                }
            } catch {
                callback(output)
                return
            }
            print("doInBackground: order-id : \(orderID)")
            //  validate order
            requestParams = JSONObject()
            requestParams["order_id"] = orderID
            print("doInBackground: order-validate -> : \(requestParams)")

            if let resp = self.requestPOSTSync(method: "order-validate", withParams: requestParams) {
                answer = resp
            } else {
                callback(output)
                return
            }

            print("doInBackground: order-validate <- : \(answer)")
            if let answer = answer["status"] as? String {
                if answer == "error" {
                    let _ = self.orderCancel(orderID) { b in

                    }
                    callback(output)
                    return
                }
            } else {
                callback(output)
                return
            }
            if (params.from == PaymentMethod.PAYEER_EUR ||
                    params.from == PaymentMethod.PAYEER_RUB ||
                    params.from == PaymentMethod.PAYEER_USD) {
                output.linkForPayeer = "https://prostocash.com/payeer-send/?id=\(orderID)"
                output.status = nil
                print("doInBackground: payeer link : \(output.linkForPayeer)")
                callback(output)
                return
            }
            //  order pay info
            requestParams = JSONObject()
            requestParams["order_id"] = orderID
            print("doInBackground: order-pay-info -> : \(requestParams)")

            if let resp = self.requestPOSTSync(method: "order-pay-info", withParams: requestParams) {
                answer = resp
            } else {
                callback(output)
                return
            }

            print("doInBackground: order-pay-info <- : \(answer)")
            if let answer = answer["status"] as? String {
                if answer == "error" {
                    let _ = self.orderCancel(orderID) { b in

                    }
                    callback(output)
                    return
                }
            } else {
                callback(output)
                return
            }
            var recipientAddress: String! = nil
            do {
                if let addr = try (answer ~ "value" ~~ "info" ~ 0)["value"] as? String {
                    recipientAddress = addr
                } else {
                    callback(output)
                    return
                }
            } catch {
                callback(output)
                return
            }

            self.startTransaction(params.from, params.addressFrom, recipientAddress!, params.howManyIn, params.btcFee, params.ethGasLimit, params.ethGasPrise) { succeeded in
                if succeeded {
                    requestParams = JSONObject()
                    requestParams["order_id"] = orderID
                    print("doInBackground: order-confirm -> : \(requestParams)")

                    if let resp = self.requestPOSTSync(method: "order-confirm", withParams: requestParams) {
                        answer = resp
                    } else {
                    }

                    print("doInBackground: order-confirm <- : \(answer)")
                    output.status = true
                    callback(output)
                    return
                } else {
                    let _ = self.orderCancel(orderID) { b in

                    }
                    callback(output)
                    return
                }
            }
        }
    }

    private func startTransaction(_ from: PaymentMethod, _ addressFrom: String,
                                  _ recipientAddress: String, _ amount: Decimal,
                                  _ btcFee: Decimal!, _ ethGasLimit: Decimal,
                                  _ ethGasPrise: Decimal, callback: @escaping (Bool)->()) {
        switch (from) {
        case .BTC:
//            let amountSatoshi = amount.multiplying(by: Decimal(string: "100000000")).uint64Value
//            let btcFeeSatoshi = btcFee == nil ? Decimal(integerLiteral: DEFAULT_TX_FEE)
//                    : btcFee.multiplying(by: Decimal(string: "100000000"))
            print("startTransaction: sending btc from \(addressFrom) to \(recipientAddress) " +
                    "value is \(amount) BTC((amountSatoshi) Satoshi) with fee is " +
                    "\(btcFee) BTC((btcFeeSatoshi) Satoshi) started")
            sendBitcoins(to: recipientAddress, amount: UInt64(NSDecimalNumber(decimal: amount)))
//                    Transaction transaction
//                    SendRequest sendRequest
//                    do {
//                        sendRequest = SendRequest.to(Address.fromBase58(Constants.NETWORK_PARAMETERS, recipientAddress), Coin.valueOf(amountSatoshi.longValue()))
//                    } catch {
//                        return false
//                    }
//                    sendRequest.feePerKb = Coin.valueOf(btcFeeSatoshi.longValue())
//                    transaction = walletApplication.getWallet().sendCoinsOffline(sendRequest)
//                    transaction.verify()
//                    BRWalletManager.sharedInstance()?.wallet?.transaction(for: amountSatoshi, to: recipientAddress, withFee: true)
            callback(true)
            return
//            case ETH:
//                if (ethGasPrise == nil) ethGasPrise = NewEthereumLibrary.instance.getNormalGasPrise()
//                if (ethGasLimit == nil) ethGasLimit = NewEthereumLibrary.instance.getNormalGasLimit()
//                return NewEthereumLibrary.instance.send_bitch(recipientAddress, amount, ethGasPrise, ethGasLimit) == NewEthereumLibrary.TX_STATUS.DONE
            case .YANDEX_MONEY:
                requestPayment(to: recipientAddress, amount: amount as Decimal) { request_id in
                    if let rid = request_id {
                        self.processPayment(request_id: rid) { jsonObject in
                            if let jobj = jsonObject {
                                callback(true)
                                return
                            } else {
                                print("Error processing payment")
                                callback(false)
                                return
                            }
                        }
                    } else {
                        print("Error getting request_id")
                        callback(false)
                        return
                    }
                }

//                HashMap<String, String> paramsForRequestPaymentApiRequest = HashMap<>()
//                paramsForRequestPaymentApiRequest["to"] = recipientAddress
//                paramsForRequestPaymentApiRequest["amount_due"] = amount.toString()
//                paramsForRequestPaymentApiRequest["comment"] = "Пополнение BTC через Paymon"
//                print("startTransaction: paramsForRequestPaymentApiRequest : " + paramsForRequestPaymentApiRequest)
//                var requestPayment = nil
//                do {
//                    requestPayment = YandexMoney.instance.getApiClient().execute(RequestPayment.Request.newInstance("p2p", paramsForRequestPaymentApiRequest))
//                } catch {
//                    return false
//                }
//                print("doInBackground: requestPayment : " + requestPayment)
//                var requestID = requestPayment.requestId
//                print("doInBackground: requestId " + requestID)
//                var processPayment = nil
//                do {
//                    processPayment = YandexMoney.instance.getApiClient().execute(ProcessPayment.Request(requestID))
//                } catch {
//                    return false
//                }
//                print("doInBackground: processPayment" + processPayment)
//                return true
        default:
            callback(false)
            return
        }
    }

    var amount: UInt64!
    var okAddress, okIdentity: String!

    // TODO: TEST
    public func sendBitcoins(to: String, amount: UInt64) {
        okAddress = to//.text
        let str: String = to//.text
        if let manager = BRWalletManager.sharedInstance(), let wallet = manager.wallet {
            var i: Int = 0
            if let req = BRPaymentRequest(string: str) {
                let arr:[UInt8] = (str.hexToData() as Data).reversed()
                let data = Data(bytes: arr)
//                let data2: ReversedCollection<Data> = (str.hexToData() as Data).reversed()
                i += 1
                // if the clipboard contains a known txHash, we know it's not a hex encoded private key
                print("data.count=\(data.count)");

                let bytes = UInt256(u8: data.withUnsafeBytes( { $0.pointee }))
//                if let bytes = data[0]. as? UInt256 {
                    if data.count == MemoryLayout<UInt256>.size && wallet.transaction(forHash: bytes) != nil {
                        print("clipboard contains a known txHash error")
                    }
//                } else {
//                    print("ERROR 1")
//                }
                if req.paymentAddress.isValidBitcoinAddress() || str.isValidBitcoinPrivateKey() || str.isValidBitcoinBIP38Key() || (req.r.count > 0 && req.scheme.isEqual("bitcoin")) {
                    print("Send 1")
                    perform(#selector(self.confirmRequest), with: req, afterDelay: 0.1)
                }
            } else {
                print("SEND ERROR 2")
            }
        }
    }

    func confirmRequest(_ request: BRPaymentRequest) {
        if !request.isValid {
            if request.paymentAddress.isValidBitcoinPrivateKey() || request.paymentAddress.isValidBitcoinBIP38Key() {
                print("Send sweep")
                //            [self confirmSweep:request.paymentAddress];
            } else {
                DispatchQueue.main.async {
                    UIAlertView(title: NSLocalizedString("not a valid bitcoin address", comment: ""), message: request.paymentAddress, delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                }
                //            [self cancel:nil];
            }
        } else if request.r.count > 0 {
            // payment protocol over HTTP
//            (parent?.parent? as? Any)?.startActivity(withTimeout: 20.0)
            BRPaymentRequest.fetch(request.r, timeout: 20.0, completion: { (_ req: BRPaymentProtocolRequest?, _ error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
//                    (self.parent?.parent? as? Any)?.stopActivity(withSuccess: !error)
                    if let error = error, !request.paymentAddress.isValidBitcoinAddress() {
                        UIAlertView(title: NSLocalizedString("couldn't make payment", comment: ""), message: error.localizedDescription, delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                        //                    [self cancel:nil];
                    } else {
                        self.confirmProtocolRequest(error != nil ? request.protocolRequest! : req!)
                    }
                })
            })
        } else {
            confirmProtocolRequest(request.protocolRequest)
        }

    }

    //let LOCK = "\xF0\x9F\x94\x92"
    //let REDX = "\xE2\x9D\x8C"
    func confirmProtocolRequest(_ protoReq: BRPaymentProtocolRequest) {
        if let manager = BRWalletManager.sharedInstance(), let wallet = manager.wallet {
            var tx: BRTransaction? = nil
            var amount: UInt64 = 0
            var fee: UInt64 = 0
            var address: String = NSString.address(withScriptPubKey: protoReq.details.outputScripts.first as! Data)
            var valid: Bool = protoReq.isValid
            var outputTooSmall = false
            if !(valid && protoReq.errorMessage.isEqual(NSLocalizedString("request expired", comment: ""))) {
                UIAlertView(title: NSLocalizedString("bad payment request", comment: ""), message: protoReq.errorMessage, delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                //        [self cancel:nil];
                return
            }
            //TODO: check for duplicates of already paid requests
            if amount == 0 {
                for outputAmount: NSNumber in protoReq.details.outputAmounts as! [NSNumber] {
                    if UInt64(outputAmount) > 0 && UInt64(outputAmount) < TransactionManager.TM_TX_MIN_OUTPUT_AMOUNT {
                        outputTooSmall = true
                    }
                    amount += UInt64(outputAmount)
                }
            } else {
                self.amount = amount
            }

            if wallet.containsAddress(address) {
                DispatchQueue.main.async {
                    UIAlertView(title: "", message: NSLocalizedString("this payment address is already in your wallet", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                    //        [self cancel:nil];
                }
                return
            } else if let str = UIPasteboard.general.string, !(okAddress.isEqual(address) && wallet.addressIsUsed(address) && str.isEqual(address)) {
                request = protoReq
                okAddress = address
                DispatchQueue.main.async {
                    UIAlertView(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString(
                            "ADDRESS ALREADY USED\n" +
                                    "bitcoin addresses are intended for single use only\n" +
                                    "re-use reduces privacy for both you and the recipient and can result in loss if \\\n" +
                                    "the recipient doesn't directly control the address\n", comment: ""), delegate: self, cancelButtonTitle: "", otherButtonTitles: NSLocalizedString("ignore", comment: ""), NSLocalizedString("cancel", comment: "")).show()
                }
                return
            } else if protoReq.errorMessage.count > 0 && protoReq.commonName.count > 0 && !okIdentity.isEqual(protoReq.commonName) {
                request = protoReq
                okIdentity = protoReq.commonName
                DispatchQueue.main.async {
                    UIAlertView(title: NSLocalizedString("payee identity isn't certified", comment: ""), message: protoReq.errorMessage, delegate: self, cancelButtonTitle: "", otherButtonTitles: NSLocalizedString("ignore", comment: ""), NSLocalizedString("cancel", comment: "")).show()
                }
                return
            } else if amount == 0 || amount == UINT64_MAX {
                // TODO?
//                let amountController = storyboard.instantiateViewController(withIdentifier: "AmountViewController")
//
//                request = protoReq
//
//                if protoReq.commonName.count > 0 {
//                    if valid && !protoReq.pkiType.isEqual("none") {
//                        amountController.to = "LOCK " + (sanitizeString(protoReq.commonName))
//                    } else if protoReq.errorMessage.count > 0 {
//                        amountController.to = "REDX " + (sanitizeString(protoReq.commonName))
//                    } else {
//                        amountController.to = sanitizeString(protoReq.commonName)
//                    }
//                } else {
//                    amountController.to = address
//                }
//
//                amountController.navigationItem?.title = "\(manager.string(forAmount: manager.wallet.balance)) (\(manager.localCurrencyString(forAmount: manager.wallet.balance)))"
//                navigationController?.pushViewController(amountController, animated: true)
                return

            } else if amount < TransactionManager.TM_TX_MIN_OUTPUT_AMOUNT {
                DispatchQueue.main.async {
                    UIAlertView(title: NSLocalizedString("couldn't make payment", comment: ""), message: NSLocalizedString("bitcoin payments can't be less than \(manager.string(forAmount: Int64(TransactionManager.TM_TX_MIN_OUTPUT_AMOUNT)))", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                    //        [self cancel:nil];
                }
                return
            } else if outputTooSmall {
                DispatchQueue.main.async {
                    UIAlertView(title: NSLocalizedString("couldn't make payment", comment: ""), message: NSLocalizedString("bitcoin transaction outputs can't be less than \(manager.string(forAmount: Int64(TransactionManager.TM_TX_MIN_OUTPUT_AMOUNT)))", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                    //        [self cancel:nil];
                }
                return
            }

            self.request = protoReq

            if self.amount == 0 {
                //    tx = [manager.wallet transactionForAmounts:protoReq.details.outputAmounts
                //    toOutputScripts:protoReq.details.outputScripts withFee:YES];
                tx = wallet.transaction(forAmounts: protoReq.details.outputAmounts, toOutputScripts: protoReq.details.outputScripts, withFee: true)
            } else {
                tx = wallet.transaction(forAmounts: [amount], toOutputScripts: [protoReq.details.outputScripts.first], withFee: true)
            }

            if let tx = tx {
                amount = wallet.amountSent(by: tx) - wallet.amountReceived(from: tx)
                fee = wallet.fee(for: tx)
            } else {
                //    fee = [manager.wallet feeForTxSize:[manager.wallet transactionFor:manager.wallet.balance
                //    to:address withFee:NO].size];
                //    fee += (manager.wallet.balance - amount) % 100;
                //    amount += fee;
                if let t = wallet.transaction(for: wallet.balance, to: address, withFee: false) {
                    fee = wallet.fee(forTxSize: UInt(t.size))
                    fee += (wallet.balance - amount) % 100
                    amount += fee
                }
            }

            for script: Data in protoReq.details.outputScripts as! [Data] {
                //    NSString *addr = [NSString addressWithScriptPubKey:script];
                var addr = NSString.address(withScriptPubKey: script)

                if addr == nil {
                    addr = "unrecognized address" //NSLocalizedString(@"unrecognized address", nil)
                }
                //    if ([address rangeOfString:addr].location != NSNotFound) continue;
                if (address as NSString).range(of: addr!).location != NSNotFound {
                    continue
                }
                address = address + ("\((address.count > 0) ? ", " : "")\(addr!)")

            }

            if let prompt = promptForAmount(amount, fee:fee, address:address, name:protoReq.commonName, memo:protoReq.details.memo, isSecure:valid && !protoReq.pkiType.isEqual("none")) {
                // to avoid the frozen pincode keyboard bug, we need to make sure we're scheduled normally on the main runloop
                // rather than a dispatch_async queue
                CFRunLoopPerformBlock(RunLoop.main.getCFRunLoop(), CFRunLoopMode.commonModes.rawValue, {//kCFRunLoopCommonModes
                    if tx != nil {
                        self.confirmTransaction(tx!, withPrompt: prompt, forAmount: amount);
                    }
                })
            }
        }
    }

    func confirmTransaction(_ tx: BRTransaction, withPrompt prompt: String, forAmount amount: UInt64) {
        if let manager = BRWalletManager.sharedInstance() {
            let didAuth = manager.didAuthenticate

            if let wallet = manager.wallet {
                if tx == nil { // tx is nil if there were insufficient wallet funds
                    if (!manager.didAuthenticate) {
                        manager.seed(withPrompt: prompt, forAmount: amount)
                    }

                    if (manager.didAuthenticate) {
                        let fuzz = manager.amount(forLocalCurrencyString: manager.localCurrencyString(forAmount: 1)) * 2

                        // if user selected an amount equal to or below wallet balance, but the fee will bring the total above the
                        // balance, offer to reduce the amount to available funds minus fee
                        if (self.amount <= (wallet.balance ?? 0) + UInt64(fuzz) && self.amount > 0) {
                            let amount = wallet.maxOutputAmount ?? 0

                            if (amount > 0 && amount < self.amount) {
                                DispatchQueue.main.async {
                                    UIAlertView(title: NSLocalizedString("insufficient funds for bitcoin network fee", comment: ""), message: NSLocalizedString("reduce payment amount by \(manager.string(forAmount: Int64(amount - amount))) (\(manager.localCurrencyString(forAmount: Int64(amount - amount))))?", comment: ""), delegate: self, cancelButtonTitle: NSLocalizedString("cancel", comment: ""), otherButtonTitles: "\(manager.string(forAmount: Int64(amount - amount))) (\(manager.localCurrencyString(forAmount: Int64(amount - amount))))").show()
                                }
                                self.amount = amount
                            } else {
                                DispatchQueue.main.async {
                                    UIAlertView(title: NSLocalizedString("insufficient funds for bitcoin network fee", comment: ""), message: "", delegate: self, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                UIAlertView(title: NSLocalizedString("insufficient funds", comment: ""), message: "", delegate: self, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                            }
                        }
                    } else {
                        print("Send error 3");
                        //            [self cancelOrChangeAmount];
                    }

                    if (!didAuth) {
                        manager.didAuthenticate = false
                    }
                    return;
                }

                if !wallet.sign(tx, withPrompt: prompt) {
                    DispatchQueue.main.async {
                        UIAlertView(title: NSLocalizedString("couldn't make payment", comment: ""), message: NSLocalizedString("error signing bitcoin transaction", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                    }
                }

                if (!didAuth) {
                    manager.didAuthenticate = false
                }

                if !tx.isSigned { // user canceled authentication
                    //        [self cancelOrChangeAmount];
                    print("Send error 2");
                    return;
                }

//                if (navigationController?.topViewController != parent?.parent) {
//                    navigationController?.popToRootViewController(animated: true)
//                }

                var waiting = true
                var sent = false

                BRPeerManager.sharedInstance()?.publishTransaction(tx) { error in
                    if let error = error {
                        if !waiting && !sent {
                            DispatchQueue.main.async {
                                UIAlertView(title: "couldn't make payment", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "ok", otherButtonTitles: "").show()
                            }
//                        (parent?.parent? as? Any)?.stopActivity(withSuccess: false)
                        }
                    } else if !sent { //TODO: show full screen sent dialog with tx info, "you sent b10,000 to bob"
                        sent = true;
                        tx.timestamp = Date.timeIntervalSinceReferenceDate //[NSDate timeIntervalSinceReferenceDate];
                        wallet.register(tx)
//                            view.addSubview(BRBubbleView)
                        NotificationCenter.default.post(name: NSNotification.Name("transferSuccess"), object: nil)

                        print("> Sent! <")
                        //[[[BRBubbleView viewWithText:NSLocalizedString(@"sent!", nil)
//                            center:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)] popIn]
//                            popOutAfterDelay:2.0]];
//                            [(id) self.parentViewController.parentViewController stopActivityWithSuccess:YES];
//                            [(id) self.parentViewController.parentViewController ping];
//                    (parent?.parent? as? Any)?.stopActivity(withSuccess: true)
//                    (parent?.parent? as? Any)?.ping()

                        //            if (self.callback) {
                        //                self.callback = [NSURL URLWithString:[self.callback.absoluteString stringByAppendingFormat:@"%@txid=%@",
                        //                                                                                                           (self.callback.query.length > 0) ? @"&" : @"?",
                        //                                                                                                           [NSString hexWithData:[NSData dataWithBytes:tx.txHash.u8
                        //                                                                                                                                                length:sizeof(UInt256)].reverse]]];
                        //                [[UIApplication sharedApplication] openURL:self.callback];
                        //            }

                        //            [self reset:nil];
                    }

                    waiting = false;
                    //}];
                }

                if request.details.paymentURL.count > 0 {
                    var refundAmount: UInt64 = 0;
                    let refundScript: NSMutableData = NSMutableData() //[NSMutableData data];

                    refundScript.appendScriptPubKey(forAddress: wallet.receiveAddress)

                    for amt: NSNumber in request.details.outputAmounts as! [NSNumber] {
                        refundAmount += UInt64(amt)
                    }

                    // TODO: keep track of commonName/memo to associate them with outputScripts
                    let payment = BRPaymentProtocolPayment(merchantData: request.details.merchantData, transactions: [tx], refundToAmounts: [refundAmount], refundToScripts: [refundScript], memo: nil)

                    print("posting payment to: \(request.details.paymentURL)");

                    BRPaymentRequest.post(payment, to: request.details.paymentURL, timeout: 20.0, completion: { (_ ack: BRPaymentProtocolACK?, _ error: Error?) -> Void in
                        DispatchQueue.main.async(execute: { () -> Void in
//                            (self.parent?.parent? as? Any)?.stopActivity(withSuccess: !error)
                            if let error = error {
                                if !(waiting && !sent) {
                                    DispatchQueue.main.async {
                                        UIAlertView(title: "", message: error.localizedDescription, delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
//                                    (self.parent?.parent? as? Any)?.stopActivity(withSuccess: false)
                                        //                                           [self cancel:nil];
                                    }
                                }
                            } else if !sent {
                                sent = true
                                tx.timestamp = Date.timeIntervalSinceReferenceDate
                                wallet.register(tx)
                                print(">SENT!<")
//                                self.view.addSubview(BRBubbleView(text: (ack.memo.length > 0 ? ack.memo : NSLocalizedString("sent!", comment: "")), center: CGPoint(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height / 2)).popIn().popOut(afterDelay: (ack.memo.length > 0 ? 3.0 : 2.0)))
//                                (self.parent?.parent? as? Any)?.stopActivity(withSuccess: true)
//                                (self.parent?.parent? as? Any)?.ping()
                            }

                            waiting = false
                        })
                    })
                } else {
                    waiting = false
                }
            }
        }
    }

    func promptForAmount(_ amount: UInt64, fee: UInt64, address: String, name: String, memo: String, isSecure: Bool) -> String! {
        if let manager = BRWalletManager.sharedInstance() {
            var prompt: String = (isSecure && name.count > 0) ? "LOCK " : ""
            //BUG: XXX limit the length of name and memo to avoid having the amount clipped
            if !(isSecure && request.errorMessage.count > 0) {
                prompt = prompt + (" ")
            }
            if name.count > 0 {
                prompt = prompt + (sanitizeString(name))
            }
            if !(isSecure && prompt.count > 0) {
                prompt = prompt + ("")
            }
            if !(isSecure || prompt.count == 0) {
                prompt = prompt + (address)
            }
            if memo.count > 0 {
                prompt = prompt + ("\(sanitizeString(memo))")
            }
            prompt = prompt + (NSLocalizedString("amount", comment: "") + "\(manager.string(forAmount: Int64(amount - fee))) (\(manager.localCurrencyString(forAmount: Int64(amount - fee)))")
            if fee > 0 {
                prompt = prompt + (NSLocalizedString("network fee", comment: "") + "\(manager.string(forAmount: Int64(fee))) (\(manager.localCurrencyString(forAmount: Int64(fee))))")
                prompt = prompt + (NSLocalizedString("total", comment: "") + "\(manager.string(forAmount: Int64(amount))) (\(manager.localCurrencyString(forAmount: Int64(amount))))")
            }
            return prompt;
        }
        return nil;
    }

    func sanitizeString(_ s: String) -> String {
        var sane = NSMutableString(string: s)
        CFStringTransform(sane as CFMutableString, nil, kCFStringTransformToUnicodeName, false)
        return sane as String
    }

    private func orderCancel(_ orderID: Int64, callback: @escaping (Bool)->()) {
        var requestParams = JSONObject()
        var answer: JSONObject! = JSONObject()
        requestParams["order_id"] = orderID
        print("doInBackground: order-cancel -> : \(requestParams)")

        requestPOST(method: "order-cancel", withParams: requestParams) { answer in
            if answer == nil {
                callback(false)
                return;
            }
            print("doInBackground: order-cancel <- : \(answer)")
            callback(true)
            return;
        }
    }

    public class TransactionTaskInput {
        let from, to: PaymentMethod
        let howManyIn, howManyOut: Decimal
        let addressFrom, addressTo: String
        let btcFee: Decimal
        let ethGasPrise: Decimal
        let ethGasLimit: Decimal

        public init(_ from: PaymentMethod, _ to: PaymentMethod,
                    _ howManyIn: Decimal, _ howManyOut: Decimal,
                    _ addressFrom: String, _ addressTo: String,
                    _ btcFee: Decimal, _ ethGasLimit: Decimal,
                    _ ethGasPrise: Decimal) {
            self.from = from
            self.to = to
            self.howManyIn = howManyIn
            self.howManyOut = howManyOut
            self.addressFrom = addressFrom
            self.addressTo = addressTo
            self.btcFee = btcFee
            self.ethGasPrise = ethGasPrise
            self.ethGasLimit = ethGasLimit
        }
    }

    public class TransactionTaskOutput {
        public var status: Bool!
        public var linkForPayeer: String!

        public init(_ status: Bool!, _ linkForPayeer: String!) {
            self.status = status
            self.linkForPayeer = linkForPayeer
        }
    }
}
