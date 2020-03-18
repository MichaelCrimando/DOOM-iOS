//
//  ProxyManager.swift
//  DOOM
//
//  Created by Michael Crimando on 3/18/20.
//
import Foundation
import SmartDeviceLink

class ProxyManager: NSObject, SDLStreamingMediaManagerDataSource, SDLServiceEncryptionDelegate {
    func serviceEncryptionUpdated(serviceType type: SDLServiceType, isEncrypted encrypted: Bool, error: Error?) {
        print(" I have no idea what this fnuction is for but protocol baby")
    }
    
    
    // Manager
    public var sdlManager: SDLManager!

    // Singleton
   @objc static let sharedManager = ProxyManager()
    
    #if GAME_DOOM
    private let appName = "DOOM"
    private let appId = "666"
    private let appImageName = "DOOM_76.png"
    
    #elseif GAME_DOOM2
    private let appName = "DOOM II"
    private let appId = "6666"
    private let appImageName = "DOOM2_76.png"
    
    #elseif GAME_FINALDOOM
    private let appName = "Final DOOM"
    private let appId = "66666"
    private let appImageName = "FinalDOOM_76.png"
    
    #else
    private let appName = "SIGIL"
    private let appId = "666666"
    private let appImageName = "SIGIL_76.png"
    #endif
    
    private var appType : SDLAppHMIType = .navigation
    var isConnected : Bool = false
    var isVideoStreamStarted: Bool = false
    var sdlViewSize:CGSize = CGSize(width: 200, height: 200)
    
    
    var subscribeVehicleData : SDLSubscribeVehicleData
    
    private var _hmiLevel: SDLHMILevel = .none
    var hmiLevel: SDLHMILevel{
        get {
            return _hmiLevel
        }
    }
    
    //viewcontroller to send to hmi
    private var _sdlVC:SDLCarWindowViewController = SDLCarWindowViewController()
    var sdlViewController: SDLCarWindowViewController {
        get {
            return _sdlVC
        }
        set {
            _sdlVC = newValue
            if sdlManager.streamManager != nil {
                sdlManager.streamManager?.rootViewController = newValue
            }
        }
    }
    
    
    
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
    
    
    
    private override init() {
        subscribeVehicleData = SDLSubscribeVehicleData()
        super.init()

        // Used for USB Connection
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, fullAppId: appId)
        lifecycleConfiguration.shortAppName = appName
        
        if let appImage = UIImage(named: appImageName) {
          let appIcon = SDLArtwork(image: appImage, name: appName, persistent: true, as: .PNG )
          lifecycleConfiguration.appIcon = appIcon
        }

        SDLLockScreenConfiguration.enabled()
        SDLLogConfiguration.default()
        
        lifecycleConfiguration.appType = appType
        
        
        let encryptionConfig = SDLEncryptionConfiguration(securityManagers: [FMCSecurityManager.self], delegate: self as! SDLServiceEncryptionDelegate)
        let streamingConfig = SDLStreamingMediaConfiguration.secure()
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: .disabled(), logging: .default(), streamingMedia: streamingConfig, fileManager: .default(), encryption: encryptionConfig)
        
        sdlManager = SDLManager(configuration: configuration, delegate: self)
        
        
        
        self.isVideoStreamStarted = true
        NotificationCenter.default.addObserver(self, selector: #selector(vehicleDataAvailable(_:)), name: .SDLDidReceiveVehicleData, object: nil)
        NSObject.load()
        
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

   @objc func connect() {
       // Start watching for a connection with a SDL Core
       DispatchQueue.global(qos: .background).async {
       self.sdlManager.start { (success, error) in
           if success {
               // Your app has successfully connected with the SDL Core
               self.isConnected = true
           }
       }
       }
   }
    
    /**
     *  Disconnect app on SYNC
     */
    @objc func disconnect() {
        sdlManager.stop()
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
    
    @objc func didReceiveGetSystemCapabilityResponse(_ notification:SDLRPCResponseNotification){
        guard let response: SDLGetSystemCapabilityResponse = notification.response as? SDLGetSystemCapabilityResponse else {return}
        //set view size
        let height:Double? = response.systemCapability?.videoStreamingCapability?.preferredResolution?.resolutionHeight.doubleValue
        let width:Double? = response.systemCapability?.videoStreamingCapability?.preferredResolution?.resolutionWidth.doubleValue
        if width != nil && height != nil{
          let size:CGSize = CGSize(width: width!, height: height!)
          self.sdlViewSize = size
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
//    DispatchQueue.global(qos: .background).async {
//        if newLevel != .none {
//            UIApplication.shared.isIdleTimerDisabled = true
//        } else {
//            UIApplication.shared.isIdleTimerDisabled = false
//        }
//    }
  }
}
