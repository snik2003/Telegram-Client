//
//  TextMessage.swift
//  tdlib-ios
//
//  Created by Anton Glezman on 05/10/2019.
//  Copyright © 2019 Anton Glezman. All rights reserved.
//

import Foundation

struct TextMessage {
 
    let id: Int64
    let chatId: Int64
    let date: Foundation.Date
    var senderUserId: Int
    let isChannelPost: Bool
    private(set) var text: String?
    var user: UserInfo?
    var isOutgoing: Bool
}


extension TextMessage {
    
    init(_ message: Message) {
        id = message.id
        chatId = message.chatId
        date = Foundation.Date(timeIntervalSince1970: TimeInterval(message.date))
        senderUserId = message.sender.userId
        isChannelPost = message.isChannelPost
        text = TextMessage.makeText(message.content)
        isOutgoing = message.isOutgoing
    }
    
    mutating func updateContent(_ content: MessageContent) {
        text = TextMessage.makeText(content)
    }

    private static func makeText(_ content: MessageContent) -> String? {
        switch content {
        case .messageText(let text):
            return text.text.text
            
        case .messageAnimation:
            return "<Анимация>"
            
        case .messageAudio:
            return "<Аудиозапись>"
            
        case .messageDocument:
            return "<Документ>"
            
        case .messagePhoto:
            return "<Фотография>"
            
        case .messageSticker(let sticker):
            return sticker.sticker.emoji
            
        case .messageVideo:
            return "<Видеозапись>"
        
        default:
            return nil
        }
    }
}
