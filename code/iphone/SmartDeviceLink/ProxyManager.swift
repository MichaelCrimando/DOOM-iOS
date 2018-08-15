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
    private let appName = "Doom"
    private let appId = "666"
    fileprivate var sdlManager: SDLManager!
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
        
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName:appName, appId: appId)
        lifecycleConfiguration.shortAppName = appName
        
        if let appImage = UIImage(named: "Doom App Icon") {
            let appIcon = SDLArtwork(image: appImage, name: "Doom", persistent: true, as: .JPG)
            lifecycleConfiguration.appIcon = appIcon
        }
        
        
        SDLLockScreenConfiguration.enabled()
        SDLLogConfiguration.default()
        
        lifecycleConfiguration.appType = .media
        let frameRate:Int = 30
        let averageBitRate:Int = 1000000
        
        
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: .enabled(), logging: .default())
        
        //setup Streaming configuration
        let videoEncoderSettings = [kVTCompressionPropertyKey_ExpectedFrameRate as String: frameRate, kVTCompressionPropertyKey_AverageBitRate as String: averageBitRate]
        
        //TODO: Implement Secure streaming
        //let streamingConfig = SDLStreamingMediaConfiguration(securityManagers: [FMCSecurityManager.self], encryptionFlag: self.encryptionSetting, videoSettings: videoEncoderSettings, dataSource: self, rootViewController: self.sdlViewController)
        
        sdlManager = SDLManager(configuration: configuration, delegate: nil)
        
        
    }
    func connect() {
        // Start watching for a connection with a SDL Core
        sdlManager.start { (success, error) in
            if success {
                // Your app has successfully connected with the SDL Core
            }
        }
    }
}


//extension ProxyManager: SDLManagerDelegate {
//    func managerDidDisconnect() {
//        print("Manager disconnected!")
//    }
//
//    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel){
//        print("Doom went from HMI level \(oldLevel) to HMI level \(newLevel)")
//    }
//}
