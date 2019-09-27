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
    @objc public var isVehicleDataSubscribed : Bool = false
    @objc public var bodyData : SDLBodyInformation = SDLBodyInformation() //Door - 1 = open, 0 = closed
    private var _steeringWheelAngle : SDLFloat = 0 as SDLFloat //On a scale from 480 (all the way left) to -480 (all the way right).
    @objc public var steeringWheelAngle: CGFloat {
        get {
            let _x = _steeringWheelAngle as! CGFloat
            if(_x >= -10 && _x <= 10) { //Throw some dead zone in there
                return 0.0
            } else {
                return _x/95
            }
        }
    }
    @objc public var headLampStatus : SDLHeadLampStatus = SDLHeadLampStatus()
    private var _accelPedalPosition : SDLFloat = 0 as SDLFloat //On scale from 0 - 100 (percent pressed down)
    @objc public var accelPedalPosition : CGFloat {
        get {
            var _x = _accelPedalPosition as! CGFloat
            //need to keep between 0 and 1
            _x = _x/10.0
            if(_x >= 1.0) {
                return 1.0
            } else {
                return _x
            }
        }
    }
    private var _brakingStatus : SDLVehicleDataEventStatus = .no
    @objc public func isDriverBraking() -> Bool {
        if _brakingStatus == .yes {
            return true
        } else {
            return false
        }
    }
    @objc public var isEncryptionEnabled : Bool = true
    
    
    
    // Singleton
    @objc public static let sharedManager = ProxyManager()
    
    private override init() {
        subscribeVehicleData = SDLSubscribeVehicleData()
        super.init()
        
        
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName:appName, appId: appId)
        lifecycleConfiguration.shortAppName = appName
        
        
        let appIcon = SDLArtwork(image: #imageLiteral(resourceName: "DOOM_72.png"), name: "Doom", persistent: true, as: .JPG)
        lifecycleConfiguration.appIcon = appIcon
        
        
        SDLLockScreenConfiguration.enabled()
        SDLLogConfiguration.default()
        
        if(SettingsBundleHelper.apptype() == "Navigation"){
            lifecycleConfiguration.appType = .navigation
        } else {
            lifecycleConfiguration.appType = .projection
        }
        
        //setup Streaming configuration
        //Nevermind, this seems to work better when set to nil
//        let frameRate:Int = 30
//        let averageBitRate:Int = 1000000
//        let videoEncoderSettings = [kVTCompressionPropertyKey_ExpectedFrameRate as String: frameRate, kVTCompressionPropertyKey_AverageBitRate as String: averageBitRate]

        
        isEncryptionEnabled = SettingsBundleHelper.isEncryptionEnabled()
        let encryptionFlag:SDLStreamingEncryptionFlag = SettingsBundleHelper.isEncryptionEnabled() ? SDLStreamingEncryptionFlag.authenticateAndEncrypt : SDLStreamingEncryptionFlag.none
        let streamingConfig : SDLStreamingMediaConfiguration = SDLStreamingMediaConfiguration(securityManagers: [FMCSecurityManager.self], encryptionFlag: encryptionFlag, videoSettings: nil, dataSource: self, rootViewController: self.sdlViewController)
        streamingConfig.carWindowRenderingType = .viewAfterScreenUpdates
        

        
        
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: nil, logging: nil, streamingMedia: streamingConfig)
        sdlManager = SDLManager(configuration: configuration, delegate: self)
        
        self.isVideoStreamStarted = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(vehicleDataAvailable(_:)), name: .SDLDidReceiveVehicleData, object: nil)
        
    }
    
    @objc func vehicleDataAvailable(_ notification: SDLRPCNotificationNotification) {
        guard let onVehicleData = notification.notification as? SDLOnVehicleData else {
            return
        }
        bodyData = onVehicleData.bodyInformation ?? bodyData

        print("Driver door: \(bodyData.driverDoorAjar ?? NSNumber(value: 666))")
        _steeringWheelAngle = onVehicleData.steeringWheelAngle ?? _steeringWheelAngle
        headLampStatus = onVehicleData.headLampStatus ?? headLampStatus
        _accelPedalPosition = onVehicleData.accPedalPosition ?? _accelPedalPosition
        _brakingStatus = onVehicleData.driverBraking ?? _brakingStatus

    }
    
    @objc public func connect() {
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
    
    @objc public func setStreamViewController(_ vc:UIViewController) {
        self.sdlManager.streamManager?.rootViewController = vc
    }
    func subscribeToVehicleData(){
        print("Subscribing to vehicle data...")
        subscribeVehicleData.bodyInformation = true as NSNumber & SDLBool
        subscribeVehicleData.accPedalPosition = true as NSNumber & SDLBool
        subscribeVehicleData.steeringWheelAngle = true as NSNumber & SDLBool
        subscribeVehicleData.headLampStatus = true as NSNumber & SDLBool
        subscribeVehicleData.driverBraking = true as NSNumber & SDLBool
        
        self.sdlManager.send(request: subscribeVehicleData) { (request, response, error) in
            guard let response = response as? SDLSubscribeVehicleDataResponse else { return }
            
            guard response.success.boolValue == true else {
                if response.resultCode == .disallowed {
                    // Not allowed to register for this vehicle data.
                } else if response.resultCode == .userDisallowed {
                    // User disabled the ability to give you this vehicle data
                } else if response.resultCode == .ignored {
                    if let bodyDataResponse = response.bodyInformation {
                        if bodyDataResponse.resultCode == .dataAlreadySubscribed {
                            // You have access to this data item, and you are already subscribed to this item so we are ignoring.
                        } else if bodyDataResponse.resultCode == .vehicleDataNotAvailable {
                            // You have access to this data item, but the vehicle you are connected to does not provide it.
                        } else {
                            print("Unknown reason for being ignored: \(bodyDataResponse.resultCode)")
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
            print("Vehicle data subscribed")
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
            print("Encryption Settings: \(SettingsBundleHelper.isEncryptionEnabled())")
            // We entered full
            print("entered HMI full")
            if(!self.isVehicleDataSubscribed){
                self.subscribeToVehicleData()
            }
        }
    }
}
