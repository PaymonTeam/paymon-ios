//
// Created by Vladislav on 01/10/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import SystemConfiguration

//protocol NetworkReachabilityDelegate {
//    func onNetworkReachabilityChanged(isReachable:Bool)
//}

@objc class NetworkReachability : NSObject {
    private var networkReachability: SCNetworkReachability?
    private var notifying: Bool = false
    private var delegate:NetworkReachabilityDelegate?

    init?(delegate: NetworkReachabilityDelegate) {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout.size(ofValue: address))
        address.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &address, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            return nil
        }

        networkReachability = defaultRouteReachability

        super.init()

        self.delegate = delegate
        if networkReachability == nil {
            return nil
        }
    }

    func startNotifier() -> Bool {

        guard notifying == false else {
            return false
        }

        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let reachability = networkReachability, SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            if let currentInfo = info {
                let infoObject = Unmanaged<AnyObject>.fromOpaque(currentInfo).takeUnretainedValue()
                if infoObject is NetworkReachability {
                    let networkReachability = infoObject as! NetworkReachability
                    let reachabilityFlags = flags

                    let canConnect = (
                            (reachabilityFlags.contains(.connectionOnDemand) ||
                            reachabilityFlags.contains(.connectionOnTraffic)) &&
                            !reachabilityFlags.contains(.interventionRequired))

                    let isReachable = (reachabilityFlags.contains(.reachable) &&
                            (!reachabilityFlags.contains(.connectionRequired) || canConnect))

                    networkReachability.delegate?.onNetworkReachabilityChanged(isReachable)
                }
            }
        }, &context) == true else { return false }

        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) == true else { return false }

        notifying = true
        return notifying
    }

    func stopNotifier() {
        if let reachability = networkReachability, notifying == true {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode as! CFString)
            notifying = false
        }
    }

    private var flags: SCNetworkReachabilityFlags {

        var flags = SCNetworkReachabilityFlags(rawValue: 0)

        if let reachability = networkReachability, withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0)) }) == true {
            return flags
        }
        else {
            return []
        }
    }

    deinit {
        stopNotifier()
    }
}
