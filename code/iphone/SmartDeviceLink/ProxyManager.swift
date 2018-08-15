//
//  ProxyManager.swift
//  Doom
//
//  Created by Michael Crimando on 8/14/18.
//

import Foundation
import SmartDeviceLink

class ProxyManager: NSObject {
    // Manager
    fileprivate var sdlManager: SDLManager!
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
        
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName:"Doom", appId: "666")
        lifecycleConfiguration.shortAppName = "Doom"
        
        let appIcon = SDLArtwork(image: #imageLiteral(resourceName: "Doom App Icon"), name: "Doom", persistent: true, as: .PNG)
        lifecycleConfiguration.appIcon = appIcon
        SDLLockScreenConfiguration.enabled()
        SDLLogConfiguration.default()
        
        lifecycleConfiguration.appType = .navigation
        let frameRate:Int = 30
        let averageBitRate:Int = 1000000
        
        
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: .enabled(), logging: .default())
        
        //setup Streaming configuration
        let videoEncoderSettings = [kVTCompressionPropertyKey_ExpectedFrameRate as String: frameRate, kVTCompressionPropertyKey_AverageBitRate as String: averageBitRate]
        
        //TODO: Implement Secure streaming
        //let streamingConfig = SDLStreamingMediaConfiguration(securityManagers: [FMCSecurityManager.self], encryptionFlag: self.encryptionSetting, videoSettings: videoEncoderSettings, dataSource: self, rootViewController: self.sdlViewController)
        
        sdlManager = SDLManager(configuration: configuration, delegate: self)
    }
}
