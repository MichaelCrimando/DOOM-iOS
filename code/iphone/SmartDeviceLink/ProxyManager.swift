//
//  ProxyManager.swift
//  Doom
//
//  Created by Michael Crimando on 8/14/18.
//

import Foundation
import SmartDeviceLink

class ProxyManager: NSObject, SDLStreamingMediaManagerDataSource {
    // Manager
    private let appName = "DOOM"
    private let appId = "666"
    var isVideoStreamStarted: Bool = false
    var sdlViewController:UIViewController? = blankViewController()
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
        
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName:appName, appId: appId)
        lifecycleConfiguration.shortAppName = appName
        

        let appIcon = SDLArtwork(image: #imageLiteral(resourceName: "DOOM_72.png"), name: "Doom", persistent: true, as: .JPG)
        lifecycleConfiguration.appIcon = appIcon
        
        
        SDLLockScreenConfiguration.enabled()
        SDLLogConfiguration.default()
        
        lifecycleConfiguration.appType = .navigation
        let frameRate:Int = 30
        let averageBitRate:Int = 1000000
        
        //setup Streaming configuration
        let videoEncoderSettings = [kVTCompressionPropertyKey_ExpectedFrameRate as String: frameRate, kVTCompressionPropertyKey_AverageBitRate as String: averageBitRate]
        
        //TODO: Implement Secure streaming
        
        let streamingConfig = SDLStreamingMediaConfiguration(securityManagers: nil, encryptionFlag: SDLStreamingEncryptionFlag.none, videoSettings: videoEncoderSettings, dataSource: self, rootViewController: self.sdlViewController)
        streamingConfig.carWindowRenderingType = .viewAfterScreenUpdates
        
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: nil, logging: nil, streamingMedia: streamingConfig)
        sdlManager = SDLManager(configuration: configuration, delegate: self)
        
        self.isVideoStreamStarted = true
        
    }
    func connect() {
        // Start watching for a connection with a SDL Core
        sdlManager.start { (success, error) in
            if success {
                // Your app has successfully connected with the SDL Core
            }
        }
    }
    
    func preferredVideoFormatOrder(fromHeadUnitPreferredOrder headUnitPreferredOrder: [SDLVideoStreamingFormat]) -> [SDLVideoStreamingFormat] {
        return headUnitPreferredOrder
    }
    
    func resolution(fromHeadUnitPreferredResolution headUnitPreferredResolution: SDLImageResolution) -> [SDLImageResolution] {
        let height:Int = Int((headUnitPreferredResolution.resolutionHeight as! Double))
        let width:Int = Int((headUnitPreferredResolution.resolutionWidth as! Double))
        let imageRes = SDLImageResolution(width: UInt16(width), height: UInt16(height))
        return [imageRes]
    }
    

    public var sdlManager: SDLManager!
    var streamManager: SDLStreamingMediaManager? {
//        if !isConnected {
//            return nil
//        }
        return self.sdlManager.streamManager
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
