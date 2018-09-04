//
//  SettingsBundleHelper.swift
//  Doom
//
//  Created by Michael Crimando on 9/4/18.
//

import Foundation
class SettingsBundleHelper {
    struct SettingsBundleKeys {
        static let IsEncryptionEnabled = "isEncryptionEnabled"
    }
    
    class func isEncryptionEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: SettingsBundleKeys.IsEncryptionEnabled)
    }
}
