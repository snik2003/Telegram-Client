//
//  K2Config.swift
//  K2Consult
//
//  Created by Сергей Никитин on 30.10.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import Foundation

class K2Config: Codable {
    
    private static let configKeyName = "K2_CONFIG"
    static let phoneKeyName = "K2_AUTHORISED_PHONE_NUMBER"
    
    var phone = ""
    var trackTelegramMessages = false
    var guid = ""
    var server = ""
    
    init() {
        self.load()
    }
    
    func set(config: K2Config) {
        self.phone = config.phone
        self.trackTelegramMessages = config.trackTelegramMessages
        self.guid = config.guid
        self.server = config.server
    }
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: K2Config.configKeyName)
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.object(forKey: K2Config.configKeyName) as? Data {
            let decoder = JSONDecoder()
            if let config = try? decoder.decode(K2Config.self, from: data) {
                self.set(config: config)
            }
        }
    }
    
    func remove() {
        UserDefaults.standard.removeObject(forKey: K2Config.configKeyName)
    }
}
