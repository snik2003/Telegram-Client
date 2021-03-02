//
//  ChatListService.swift
//  tdlib-ios
//
//  Created by Anton Glezman on 30/09/2019.
//  Copyright © 2019 Anton Glezman. All rights reserved.
//

import Foundation

protocol ChatListServiceDelegate: class {
    func autorizationStateUpdated(state: AuthorizationState)
    func incomingTextMessage(user: User, message: TextMessage)
    func incomingCall(user: User, call: Call)
}


final class ChatListService: UpdateListener {
    
    // MARK: - Private properties
    private let api: TdApi
    

    // MARK: - Public properties
    weak var delegate: ChatListServiceDelegate?
    
    // MARK: - Init
    init(tdApi: TdApi) {
        self.api = tdApi
    }
    
    // MARK: - Override
    
    func getUserInfo(_ message: TextMessage, userId: Int) throws {
        if userId > 0 {
            try self.api.getUser(userId: userId) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    self.delegate?.incomingTextMessage(user: user, message: message)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func onUpdate(_ update: Update) {
        
        switch update {
        case .updateNewMessage(let update):
            let message = update.message
            let msg = TextMessage(message)
            
            if message.isOutgoing == true {
                print("===update new outcoming message to \(message.chatId)===")
                try? self.getUserInfo(msg, userId: Int(message.chatId))
            } else {
                print("===update new incmoing message from \(message.sender.userId)===")
                try? self.getUserInfo(msg, userId: message.sender.userId)
            }
        case .updateCall(let update):
            if update.call.isOutgoing == false {
                print("===call with user \(update.call.userId)===")
                try? self.api.getUser(userId: update.call.userId) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let user):
                        self.delegate?.incomingCall(user: user, call: update.call)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("===outcoming call to user \(update.call.userId)===")
            }
        case .updateAuthorizationState(let state):
            print("===update authorization state on \(state.authorizationState.self)===")
            self.delegate?.autorizationStateUpdated(state: state.authorizationState)
        default:
            //print("===\(update)===")
            break
        }
    }
}

