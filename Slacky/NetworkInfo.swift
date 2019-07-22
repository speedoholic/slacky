//
//  NetworkInfo.swift
//  Slacky
//
//  Created by Kushal Ashok on 7/20/19.
//  Copyright © 2019 Kushal Ashok. All rights reserved.
//

import Foundation

struct NetworkInfo {
    var interface: String
    var success: Bool = false
    var ssid: String?
    var bssid: String?
}
