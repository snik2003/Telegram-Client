//
//  PushConfigurator.swift
//  K2Consult
//
//  Created by Сергей Никитин on 09.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit
import UserNotifications

final class PushConfigurator {
    
    static let defaultConfigurator = PushConfigurator()
    
    func askForPushNotifications(label: UILabel) {
        self.registerForPushNotifications(label: label)
    }
    
    
    func unregisterdForPushNotification() {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    func registerForPushNotifications(label: UILabel) {

        let notificationCenter = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) { didAllow, error in
            
            if !didAllow {
                OperationQueue.main.addOperation {
                    label.text = "Уведомления:  ✘"
                }
                
                #if DEBUG
                print("User has declined notifications")
                #endif
                
                return
            }
            
            if let err = error {
                OperationQueue.main.addOperation {
                    label.text = "Уведомления:  ✘"
                }
                
                #if DEBUG
                print("Push registration FAILED")
                print("ERROR: \(err.localizedDescription)")
                #endif
            } else {
                OperationQueue.main.addOperation {
                    UIApplication.shared.registerForRemoteNotifications()
                    label.text = "Уведомления:  ✔︎"
                }
                
                #if DEBUG
                print("Push registration SUCCESS")
                #endif
            }
        }
    }
}

