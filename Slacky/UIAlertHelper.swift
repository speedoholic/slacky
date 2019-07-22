//
//  UIAlertHelper.swift
//  Slacky
//
//  Created by Kushal Ashok on 7/20/19.
//  Copyright © 2019 Kushal Ashok. All rights reserved.
//

import UIKit


func getAlert(_ withTitle: String, message: String? = nil) -> UIAlertController {
    let alert = UIAlertController(title: withTitle, message: message, preferredStyle: UIAlertController.Style.alert)
    let defaultAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    alert.addAction(defaultAction)
    return alert
}
