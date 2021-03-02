//
//  AppDelegate.swift
//  K2Consult
//
//  Created by Сергей Никитин on 02.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit
import SafariServices
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    let notificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
        
        return true
    }

    func longRunningTask() {
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Get Update", expirationHandler: {
            ServiceLayer.instance.telegramService.api.client.run { data in
                do {
                    print("Executing (\(UIApplication.shared.backgroundTimeRemaining) seconds remaining)")
                    let update = try ServiceLayer.instance.telegramService.api.decoder.decode(Update.self, from: data)
                    try ServiceLayer.instance.telegramService.processUpdate(update)
                } catch {
                    ServiceLayer.instance.telegramService.logger.log(error.localizedDescription, type: .custom("Error"))
                }
                
                self.endBackgroundTask()
            }
        })
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = UIBackgroundTaskIdentifier.invalid
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("device token: \(deviceToken.hexString)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.identifier.contains(NotificationActionType.shareLink.rawValue) {
            print(NotificationActionType.shareLink.rawValue)
            let link = response.notification.request.content.categoryIdentifier
            
            if let window = UIApplication.shared.windows.first,
               let navController = window.rootViewController as? UINavigationController,
               let mainVC = navController.viewControllers.first as? MainViewController,
               let currentVC = mainVC.topViewControllerWithRootViewController(rootViewController: window.rootViewController) {
                    
                if currentVC is UIAlertController || currentVC is SFSafariViewController {
                    currentVC.dismiss(animated: false) { () -> Void in
                        mainVC.openBrowserController(link: link)
                    }
                } else if currentVC is InnerViewController {
                    mainVC.openBrowserController(link: link)
                } else {
                    Constants.shared.shareUserLink = link
                }
            } else {
                Constants.shared.shareUserLink = link
            }
        }
        
        completionHandler()
    }
    
    func scheduleEventNotification(title: String, subtitle: String, body: String, identifier: NotificationActionType, link: String?) {
        
        notificationCenter.getDeliveredNotifications { notifications in
            let content = UNMutableNotificationContent()
            
            content.title = title
            content.subtitle = subtitle
            content.body = body
            content.sound = UNNotificationSound.default
            content.badge = NSNumber(value: notifications.count + 1)
            
            if let link = link { content.categoryIdentifier = link }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "\(identifier.rawValue)-\(notifications.count + 1)", content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { (error) in
                if let error = error {
                    print("Error \(error.localizedDescription)")
                }
            }
        }
    }
}


