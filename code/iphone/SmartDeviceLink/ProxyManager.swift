//
//  ProxyManager.swift
//  DOOM
//
//  Created by Michael Crimando on 3/18/20.
//

import SmartDeviceLink

class ProxyManager: NSObject {
    
    // Manager
    fileprivate var sdlManager: SDLManager!

    // Singleton
    static let sharedManager = ProxyManager()
    
    #if GAME_DOOM
    private let appName = "DOOM"
    private let appId = "666"
    private let iconName = "DOOM_72.png"
    private let appImage = #imageLiteral(resourceName: "Icon-76.png")
    #elseif GAME_DOOM2
    private let appName = "DOOM II"
    private let appId = "6666"
    private let appImage = #imageLiteral(resourceName: "Icon-76.png")
    
    #elseif GAME_FINALDOOM
    private let appName = "Final DOOM"
    private let appId = "66666"
    private let appImage = #imageLiteral(resourceName: "Icon-76.png")
    #else
    private let appName = "SIGIL"
    private let appId = "666666"
    private let appImage = #imageLiteral(resourceName: "Icon-76.png")
    #endif

    private override init() {
        super.init()

        // Used for USB Connection
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, fullAppId: appId)

        // App icon image
        let appIcon = SDLArtwork(image: appImage, name: appName, persistent: true, as: .JPG /* or .PNG */)
            lifecycleConfiguration.appIcon = appIcon
        
        lifecycleConfiguration.shortAppName = appName
        lifecycleConfiguration.appType = .media

        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: .enabled(), logging: .default(), fileManager: .default())

        sdlManager = SDLManager(configuration: configuration, delegate: self)
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

//MARK: SDLManagerDelegate
extension ProxyManager: SDLManagerDelegate {
  func managerDidDisconnect() {
    print("Manager disconnected!")
  }

  func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
    print("Went from HMI level \(oldLevel) to HMI level \(newLevel)")
  }
}
