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
    var subscribeVehicleData : SDLSubscribeVehicleData
    var currentHmiLevel : SDLHMILevel = .none
    var isVehicleDataSubscribed : Bool = false
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        subscribeVehicleData = SDLSubscribeVehicleData()
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
        
        let streamingConfig = SDLStreamingMediaConfiguration(securityManagers: nil, encryptionFlag: SDLStreamingEncryptionFlag.none, videoSettings: nil, dataSource: self, rootViewController: self.sdlViewController)
        streamingConfig.carWindowRenderingType = .viewAfterScreenUpdates
        
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: nil, logging: nil, streamingMedia: streamingConfig)
        sdlManager = SDLManager(configuration: configuration, delegate: self)
        
        self.isVideoStreamStarted = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(vehicleDataAvailable(_:)), name: .SDLDidReceiveVehicleData, object: nil)
        
    }
    
    func vehicleDataAvailable(_ notification: SDLRPCNotificationNotification) {
        guard let onVehicleData = notification.notification as? SDLOnVehicleData else {
            return
        }
        
        let bodyData = onVehicleData.bodyInformation
        if bodyData?.driverDoorAjar == 1 {
            print("Swageroonie")
        } else {
            print("Door closed")
        }
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
        return self.sdlManager.streamManager
    }
 
    func subscribeToVehicleData(){
        print("Subscribing to vehicle data...")
        subscribeVehicleData.bodyInformation = true
        
        self.sdlManager.send(request: subscribeVehicleData) { (request, response, error) in
            guard let response = response as? SDLSubscribeVehicleDataResponse else { return }
            
            guard response.success.boolValue == true else {
                if response.resultCode == .disallowed {
                    // Not allowed to register for this vehicle data.
                } else if response.resultCode == .userDisallowed {
                    // User disabled the ability to give you this vehicle data
                } else if response.resultCode == .ignored {
                    if let bodyData = response.bodyInformation {
                        if bodyData.resultCode == .dataAlreadySubscribed {
                            // You have access to this data item, and you are already subscribed to this item so we are ignoring.
                        } else if bodyData.resultCode == .vehicleDataNotAvailable {
                            // You have access to this data item, but the vehicle you are connected to does not provide it.
                        } else {
                            print("Unknown reason for being ignored: \(bodyData.resultCode)")
                        }
                    } else {
                        print("Unknown reason for being ignored: \(String(describing: response.info))")
                    }
                } else if let error = error {
                    print("Encountered Error sending SubscribeVehicleData: \(error)")
                }
                self.isVehicleDataSubscribed = false
                return
            }
            
            self.isVehicleDataSubscribed = true
            // Successfully subscribed
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
        currentHmiLevel = newLevel
        if (newLevel == .full ) {
            // We entered full
            print("entered HMI full")
            self.subscribeToVehicleData()
        }
    }
}
