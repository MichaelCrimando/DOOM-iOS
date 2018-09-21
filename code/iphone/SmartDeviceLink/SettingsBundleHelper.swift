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
        static let AppType = "appType"
    }
    
    class func isEncryptionEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: SettingsBundleKeys.IsEncryptionEnabled)
    }
    
    
    class func apptype() -> String {
        return UserDefaults.standard.string(forKey: SettingsBundleKeys.AppType) ?? "Navigation"
    }
}
