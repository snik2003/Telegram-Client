//
//  SceneDelegate.swift
//  K2Consult
//
//  Created by Сергей Никитин on 02.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit
import SafariServices

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = notifications.count
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            DispatchQueue.main.async {
                appDelegate.endBackgroundTask()
            }
        }
        
        if let navigationVC = self.window?.rootViewController as? UINavigationController,
            let mainVC = navigationVC.viewControllers.first as? MainViewController {
            
            mainVC.checkPushNotificationsStatus()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.longRunningTask()
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return }
        
        print(url.absoluteURL)
        if let currentVC = topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
            
            if currentVC is UIAlertController || currentVC is SFSafariViewController {
                currentVC.dismiss(animated: false) { () -> Void in
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = false

                    let browserController = SFSafariViewController(url: url, configuration: config)
                    browserController.preferredControlTintColor = .white
                    browserController.preferredBarTintColor = Constants.shared.mainColor
                    
                    currentVC.present(browserController, animated: true)
                }
            } else {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = false

                let browserController = SFSafariViewController(url: url, configuration: config)
                browserController.preferredControlTintColor = .white
                browserController.preferredBarTintColor = Constants.shared.mainColor
                
                currentVC.present(browserController, animated: true)
            }
        }
    }
    
    func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController! {
        
        if rootViewController is UINavigationController {
            let navigationController = rootViewController as! UINavigationController
            return topViewControllerWithRootViewController(rootViewController: navigationController.visibleViewController2)
        } else if rootViewController.presentedViewController != nil {
            let controller = rootViewController.presentedViewController
            return topViewControllerWithRootViewController(rootViewController: controller)
        } else {
            return rootViewController
        }
    }
}


