//
// Created by Vladislav on 07/11/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

setenv("CFNETWORK_DIAGNOSTICS", "0", 1)

UIApplicationMain(CommandLine.argc, UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(
                        to: UnsafeMutablePointer<Int8>.self,
                        capacity: Int(CommandLine.argc)), nil, NSStringFromClass(AppDelegate))