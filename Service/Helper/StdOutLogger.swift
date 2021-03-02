//
//  StdOutLogger.swift
//  tdlib-ios
//
//  Created by Anton Glezman on 28/09/2019.
//  Copyright © 2019 Anton Glezman. All rights reserved.
//

import Foundation

public final class StdOutLogger: Logger {
    
    let queue: DispatchQueue
    
    public init() {
        queue = DispatchQueue(label: "Logger", qos: .userInitiated)
    }
    
    public func log(_ message: String, type: LoggerMessageType?) {
        queue.async {
            #if DEBUG
            var fisrtLine = "---------------------------"
            if let type = type {
                fisrtLine = ">> \(type.description): ---------------"
            }
            print("""
                \(fisrtLine)
                \(message)
                ---------------------------
                """)
            #endif
        }
    }
}
