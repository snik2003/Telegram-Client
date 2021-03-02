//
//  InnerViewController.swift
//  K2Consult
//
//  Created by Сергей Никитин on 02.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit
import SafariServices

class InnerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func showMessage(title: String?, message: String?, actionTitle: String?, completion: @escaping VoidClosure) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            completion()
        })
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    func showConfirmAlert(title: String?, message: String?, actionTitle: String?, completion: @escaping VoidClosure) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let nextAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            completion()
        }
        alert.addAction(nextAction)

        self.present(alert, animated: true, completion: nil)
    }
    
    func enterValueAlert(title: String?, message: String?, startValue: String? = nil, keyboardType: UIKeyboardType = .decimalPad, actionTitle: String?, completion: @escaping StringClosure) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = startValue
            textField.keyboardAppearance = .alert
            textField.keyboardType = keyboardType
            textField.textAlignment = .center
        }

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            
        }
        alert.addAction(cancelAction)
        
        let nextAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            let textField = alert.textFields![0]
            if let text = textField.text {
                completion(text)
            }
        }
        alert.addAction(nextAction)

        self.present(alert, animated: true, completion: nil)
    }
    
    func showLoading() {
        OperationQueue.main.addOperation {
            ViewControllerUtils().showActivityIndicator(uiView: self.view)
        }
    }
        
    func hideLoading() {
        OperationQueue.main.addOperation {
            ViewControllerUtils().hideActivityIndicator()
        }
    }
    
    func openBrowserController(link: String) {
        if let url = URL(string: link) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            
            let browserController = SFSafariViewController(url: url, configuration: config)
            browserController.preferredControlTintColor = .white
            browserController.preferredBarTintColor = Constants.shared.mainColor
            self.present(browserController, animated: true)
        }
    }
    
    func sendShareUserLocalNotification(user: User, app: AppEventType, link: String) {
        
        let title = "\(app.rawValue):"
        let body = "С вами поделились ссылкой на пользователя, нажмите чтобы открыть"
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleEventNotification(title: title, subtitle: "", body: body, identifier: .shareLink, link: link)
        }
    }
    
    func sendEventLocalNotification(user: User, app: AppEventType, type: EventType, isOutgoing: Bool = false, message: TextMessage? = nil) {
        
        let title = "\(app.rawValue):"
        let subtitle = "\(user.firstName) \(user.lastName) (+\(user.phoneNumber))"
        
        var body = ""
        if type == .call {
            if isOutgoing {
                body = "Исходящий звонок"
            } else {
                body = "Входящий звонок"
            }
        } else if type == .message {
            if let messageText = message?.text {
                body = String(messageText.prefix(100))
            } else if isOutgoing {
                body = "Исходящее сообщение"
            } else {
                body = "Входящее сообщение"
            }
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleEventNotification(title: title, subtitle: subtitle, body: body, identifier: .newEvent, link: nil)
        }
    }
    
    func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController! {
        
        if rootViewController is UINavigationController {
            let navigationController = rootViewController as! UINavigationController
            return self.topViewControllerWithRootViewController(rootViewController: navigationController.visibleViewController2)
        } else if rootViewController.presentedViewController != nil {
            let controller = rootViewController.presentedViewController
            
            return self.topViewControllerWithRootViewController(rootViewController: controller)
        } else {
            return rootViewController
        }
    }
}

extension UIViewController {
    
    var visibleViewController2: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.topViewController?.visibleViewController2
        } else if let presentedViewController = presentedViewController {
            return presentedViewController.visibleViewController2
        } else {
            return self
        }
    }
}
