//
//  Data+extension.swift
//  K2Consult
//
//  Created by Сергей Никитин on 11.01.2021.
//  Copyright © 2021 Snik2003. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
