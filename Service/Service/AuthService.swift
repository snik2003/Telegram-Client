//
//  AuthService.swift
//  tdlib-ios
//
//  Created by Anton Glezman on 28/09/2019.
//  Copyright © 2019 Anton Glezman. All rights reserved.
//

import UIKit

protocol AuthServiceDelegate: class {
    func waitPhoneNumber()
    func waitCode()
    func waitPassword()
    func waitRegistration()
    func waitOtherDeviceConfirmation()
    func onReady()
    func onError()
    func onPhoneError()
    func onCodeError()
    func onPasswdError()
    func onLogout()
    func onClosed()
}


final class AuthService: UpdateListener {
    
    // MARK: - Private properties
    
    private let api: TdApi
    private var authorizationState: AuthorizationState?
    
    
    // MARK: - Public properties
    
    private(set) var isAuthorized: Bool = false
    weak var delegate: AuthServiceDelegate?
    
    
    // MARK: - Init
    
    init(tdApi: TdApi) {
        self.api = tdApi
    }
    
    func getVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "no version"
        }
        
        return version
    }
    
    func onUpdate(_ update: Update) {
        if case .updateAuthorizationState(let state) = update {
            do {
                try onUpdateAuthorizationState(state.authorizationState)
            } catch {
                print(error)
            }
        }
    }
    
    func sendPhone(_ phone: String) {
        let settings = PhoneNumberAuthenticationSettings(
            allowFlashCall: false,
            allowSmsRetrieverApi: false,
            isCurrentPhoneNumber: false)
        try? self.api.setAuthenticationPhoneNumber(
            phoneNumber: phone,
            settings: settings) { [weak self] in
                self?.checkPhoneResult($0)
            }
    }
    
    func sendCode(_ code: String) {
        try? self.api.checkAuthenticationCode(code: code) { [weak self] in
            self?.checkCodeResult($0)
        }
    }
    
    func sendPassword(_ password: String) {
        try? self.api.checkAuthenticationPassword(password: password) { [weak self] in
            self?.checkResult($0)
        }
    }
    
    public func logout() {
        try? self.api.logOut() { [weak self] in
            self?.checkResult($0)
        }
    }
    
    
    // MARK: - Private methods
    
    func checkMe(completion: @escaping StringClosure) {
        try? self.api.getMe(completion: { result in
            switch result {
            case .success(let user):
                completion(user.phoneNumber)
            case .failure(let error):
                print(error.localizedDescription)
                completion("")
            }
        })
    }
    
    private func onUpdateAuthorizationState(_ state: AuthorizationState) throws {
        authorizationState = state
        
        switch state {
        case .authorizationStateWaitTdlibParameters:
            guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                return
            }
            let tdlibPath = cachesUrl.appendingPathComponent("tdlib", isDirectory: true).path
            let params = TdlibParameters(
                apiHash: "f14650867c5fdfda81c286d98989b7a4", // https://core.telegram.org/api/obtaining_api_id
                apiId: 1966754,
                applicationVersion: getVersion(),
                databaseDirectory: tdlibPath,
                deviceModel: UIDevice.current.modelName,
                enableStorageOptimizer: true,
                filesDirectory: "",
                ignoreFileNames: true,
                ignoreBackgroundsUpdates: false,
                systemLanguageCode: "ru",
                systemVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                useChatInfoDatabase: false,
                useFileDatabase: false,
                useMessageDatabase: false,
                useSecretChats: false,
                useTestDc: false)
            print(params)
            try api.setTdlibParameters(parameters: params) { [weak self] in
                self?.checkResult($0)
            }
            
        case .authorizationStateWaitEncryptionKey(_):
            let keyData = "sdfsdkjfkbsddsj".data(using: .utf8)!
            try api.checkDatabaseEncryptionKey(encryptionKey: keyData) { [weak self] in
                self?.checkResult($0)
            }
            
        case .authorizationStateWaitPhoneNumber:
            delegate?.waitPhoneNumber()
            
        case .authorizationStateWaitCode:
            delegate?.waitCode()
            
        case .authorizationStateWaitPassword(_):
            delegate?.waitPassword()
            
        case .authorizationStateReady:
            isAuthorized = true
            delegate?.onReady()
            
        case .authorizationStateLoggingOut:
            isAuthorized = false
            delegate?.onLogout()
            
        case .authorizationStateClosing:
            isAuthorized = false
            delegate?.onLogout()
            
        case .authorizationStateClosed:
            delegate?.onClosed()
            break
            
        case .authorizationStateWaitRegistration:
            break
            
        case .authorizationStateWaitOtherDeviceConfirmation(_):
            break
        }
    }
    
    private func checkResult(_ result: Result<Ok, Swift.Error>) {
        switch result {
        case .success:
            break
        case .failure(_):
            delegate?.onError()
        }
    }
    
    private func checkPhoneResult(_ result: Result<Ok, Swift.Error>) {
        switch result {
        case .success:
            break
        case .failure(_):
            delegate?.onPhoneError()
        }
    }
    
    private func checkCodeResult(_ result: Result<Ok, Swift.Error>) {
        switch result {
        case .success:
            break
        case .failure(_):
            delegate?.onCodeError()
        }
    }
    
    private func checkPasswdResult(_ result: Result<Ok, Swift.Error>) {
        switch result {
        case .success:
            break
        case .failure(_):
            delegate?.onPasswdError()
        }
    }
}
