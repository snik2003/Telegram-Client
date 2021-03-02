//
//  MainViewController.swift
//  K2Consult
//
//  Created by Сергей Никитин on 02.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit
import RMQClient
import SwiftyJSON


class MainViewController: InnerViewController {

    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var phoneViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var ignoreSwitch: UISwitch!
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var pushStatusLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    private var authService = ServiceLayer.instance.authService
    private let chatListService = ServiceLayer.instance.chatListService
    
    private let config = K2Config()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "K2 Automotive Popup"
        
        textView.isHidden = true
        textView.layer.cornerRadius = 4
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.secondaryLabel.cgColor
        
        phoneLabel.text = ""
        phoneView.isHidden = true
        phoneViewHeightConstraint.constant = 0
        ignoreSwitch.isOn = config.trackTelegramMessages
        
        guidLabel.text = config.guid.isEmpty ? Constants.shared.guid : config.guid
        serverLabel.text = config.server.isEmpty ? Constants.shared.rabbitServer : config.server
        
        authService.delegate = self
        chatListService.delegate = self
        
        ServiceLayer.instance.telegramService.run()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PushConfigurator.defaultConfigurator.askForPushNotifications(label: pushStatusLabel)
        
        if #available(iOS 13.0, *) {
            self.navigationController?.overrideUserInterfaceStyle = .light
        } else {
            self.navigationController?.view.backgroundColor = .white
        }
        
        if !Constants.shared.shareUserLink.isEmpty {
            let shareLink = Constants.shared.shareUserLink
            Constants.shared.shareUserLink = ""
            openBrowserController(link: shareLink)
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        checkPushNotificationsStatus()
    }
    
    @IBAction func loginButtonAction(_ sender: UIButton) {
        if sender.tag == 0 {
            let title = "Авторизация Telegram"
            let message = "\nВведите номер телефона, на который зарегистрирован аккаунт:\n"
            let actionTitle = "Далее"
            enterValueAlert(title: title, message: message, actionTitle: actionTitle, completion: { phone in
                self.showLoading()
                self.authService.sendPhone(phone)
            })
        } else if sender.tag == 1 {
            let title = "Выход из Telegram"
            let message = "\nВы действительно хотите выйти из аккаунта +\(config.phone)?\n"
            let actionTitle = "Выйти"
            showConfirmAlert(title: title, message: message, actionTitle: actionTitle, completion: {
                self.config.phone = ""
                self.config.save()
                
                self.authService.logout()
            })
        }
    }
    
    @IBAction func openPushSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        config.trackTelegramMessages = sender.isOn
        config.save()
        
        if config.trackTelegramMessages {
            
        }
    }
    
    @IBAction func editGuidAction() {
        let title = "ID пользователя"
        let message = "\nВведите новое значение:\n"
        let actionTitle = "Готово"
        enterValueAlert(title: title, message: message, startValue: guidLabel.text, keyboardType: UIKeyboardType.default, actionTitle: actionTitle, completion: { guid in
            if guid.isEmpty {
                self.editGuidAction()
            } else {
                self.guidLabel.text = guid
                self.config.guid = guid
                self.config.save()
            }
        })
    }
    
    @IBAction func editServerAction() {
        let title = "RabbitMQ address"
        let message = "\nВведите новое значение:\n"
        let actionTitle = "Готово"
        enterValueAlert(title: title, message: message, startValue: serverLabel.text, keyboardType: UIKeyboardType.default, actionTitle: actionTitle, completion: { server in
            if server.isEmpty {
                self.editServerAction()
            } else {
                self.serverLabel.text = server
                self.config.server = server
                self.config.save()
            }
        })
    }
    
    func checkPushNotificationsStatus() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings(completionHandler: { settings in
            if settings.authorizationStatus == .authorized {
                OperationQueue.main.addOperation {
                    self.pushStatusLabel.text = "Уведомления:  ✔︎"
                }
            } else {
                OperationQueue.main.addOperation {
                    self.pushStatusLabel.text = "Уведомления:  ✘"
                }
            }
        })
    }
    
    func sendEventOnServer(type: EventType, phone: String, text: String? = nil, isOutgoing: Bool = false) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY HH:mm:ss"
        let currentTime = dateFormatter.string(from: Date())
        
        var eventData: [String: String] = [ "PhoneNumber": "+\(phone)" ]
        if let message = text, type == .message {
            eventData["Message"] = message
            if isOutgoing {
                eventData["Direction"] = "Outbound"
            } else {
                eventData["Direction"] = "Inbound"
            }
        }
        
        var json: [String: Any] = [
            "Application": "TELEGRAM",
            "EventData": eventData,
            "Time": currentTime,
            "Type": EventType.message.rawValue,
            "UserGUID": Constants.shared.guid,
            "MessageCategory": "Unicast"
        ]
        
        if type == .call { json["Type"] = EventType.call.rawValue }
        
        let login = Constants.shared.rabbitUser
        let pass = Constants.shared.rabbitPassword
        let server = Constants.shared.rabbitServer
        
        let conn = RMQConnection(uri: "amqp://\(login):\(pass)@\(server)", delegate: RMQConnectionDelegateLogger())
        conn.start()
        
        let channel = conn.createChannel()
        let queue = channel.queue(Constants.shared.rabbitQueue)
        
        queue.subscribe { message in
            print("recieved message = \(String(data: message.body, encoding: .utf8) ?? "null")")
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            //if let jsonString = String(data: jsonData, encoding: .utf8) { print("json = \(jsonString)") }
            queue.publish(jsonData)
        }
    }
}

extension MainViewController: AuthServiceDelegate {
    
    func waitPhoneNumber() {
        textView.isHidden = true
        phoneView.isHidden = true
        phoneViewHeightConstraint.constant = 0
        
        loginButton.tag = 0
        loginButton.setTitle(" Login", for: .normal)
        loginButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        
        hideLoading()
    }
    
    func waitCode() {
        let title = "Авторизация Telegram"
        let message = "\nВведите код подтверждения:\n"
        let actionTitle = "Далее"
        
        hideLoading()
        enterValueAlert(title: title, message: message, actionTitle: actionTitle, completion: { code in
            self.authService.sendCode(code)
            self.showLoading()
        })
    }
    
    func waitPassword() {
        let title = "Авторизация Telegram"
        let message = "\nВведите пароль\nдля аккаунта +\(config.phone):\n"
        let actionTitle = "Далее"
        
        hideLoading()
        enterValueAlert(title: title, message: message, actionTitle: actionTitle, completion: { passwd in
            self.authService.sendPassword(passwd)
            self.showLoading()
        })
    }
    
    func waitRegistration() {
        let title = "Внимание!"
        let message = "\nНомер телефона +\(config.phone)\nне зарегистрирован в Telegram.\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {})
    }
    
    func waitOtherDeviceConfirmation() {
        let title = "Внимание!"
        let message = "\nНа номер телефона +\(config.phone) ожидается код подтверждения на другом устройстве.\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {})
    }
    
    func onReady() {
        loginButton.tag = 1
        loginButton.setTitle("Logout", for: .normal)
        loginButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        
        authService.checkMe { phone in
            self.config.phone = phone
            self.config.save()
            
            self.hideLoading()
            
            self.phoneLabel.text = "+\(phone)"
            self.phoneView.isHidden = false
            self.phoneViewHeightConstraint.constant = 124
            //self.textView.isHidden = false
        }
    }
    
    func onLogout() {
        textView.isHidden = true
        phoneView.isHidden = true
        phoneViewHeightConstraint.constant = 0
        
        loginButton.tag = 0
        loginButton.setTitle(" Login", for: .normal)
        loginButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        hideLoading()
    }
    
    func onClosed() {
        hideLoading()
    }
    
    func onError() {
        let title = "Внимание!"
        let message = "\nЧто-то пошло не так.\nПовторите попытку позже.\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {})
    }
    
    func onPhoneError() {
        let title = "Внимание!"
        let message = "\nНомер телефона введен некорректно\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {
            self.loginButtonAction(self.loginButton)
        })
    }
    
    func onCodeError() {
        let title = "Внимание!"
        let message = "\nНеверный код подтверждения\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {
            self.waitCode()
        })
    }
    
    func onPasswdError() {
        let title = "Внимание!"
        let message = "\nВведен неверный пароль\n"
        let actionTitle = "Готово"
        
        hideLoading()
        showMessage(title: title, message: message, actionTitle: actionTitle, completion: {
            self.waitPassword()
        })
    }
}

extension MainViewController: ChatListServiceDelegate {
    func incomingCall(user: User, call: Call) {
        if !user.phoneNumber.isEmpty && config.trackTelegramMessages {
            sendEventLocalNotification(user: user, app: .telegram, type: .call, isOutgoing: call.isOutgoing)
            sendEventOnServer(type: .call, phone: user.phoneNumber)
        }
    }
    
    func incomingTextMessage(user: User, message: TextMessage) {
        if !user.phoneNumber.isEmpty && config.trackTelegramMessages {
            
            var notContainLinks = true
            
            if let inputText = message.text {
                let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: inputText, options: [], range: NSRange(location: 0, length: inputText.utf16.count))
                
                for match in matches {
                    guard let range = Range(match.range, in: inputText) else { continue }
                    let url = String(inputText[range])
                    if url.contains("i907svws11.corp.inchcape.ru") {
                        notContainLinks = false
                        sendShareUserLocalNotification(user: user, app: .telegram, link: url)
                    }
                }
            }
            
            if notContainLinks {
                sendEventLocalNotification(user: user, app: .telegram, type: .message, isOutgoing: message.isOutgoing, message: message)
                sendEventOnServer(type: .message, phone: user.phoneNumber, text: message.text, isOutgoing: message.isOutgoing)
            }
        }
    }
    
    func autorizationStateUpdated(state: AuthorizationState) {
        switch state {
        case .authorizationStateReady:
            onReady()
        case .authorizationStateClosed:
            onLogout()
        case .authorizationStateWaitPhoneNumber:
            waitPhoneNumber()
        default:
            break
        }
    }
}

