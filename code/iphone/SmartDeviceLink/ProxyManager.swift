//
//  ProxyManager.swift
//  DOOM
//
//  Created by Michael Crimando on 3/18/20.
//
import Foundation
import SmartDeviceLink

class ProxyManager: NSObject {
    #if GAME_DOOM //TODO: Eventualley give these all their own app ID. But gotta work out backend for that
    private let appName = "DOOM"
    private let appId = "666"
    private let appImageName = "DOOM_76.png"
    private let appIconName = "DOOM"
    
    #elseif GAME_DOOM2
    private let appName = "DOOM II"
    private let appId = "666"
    private let appImageName = "DOOM2_76.png"
    private let appIconName = "DOOM2"
    
    #elseif GAME_FINALDOOM
    private let appName = "Final DOOM"
    private let appId = "666"
    private let appImageName = "FinalDOOM_76.png"
    private let appIconName = "FinalDOOM"
    
    #else
    private let appName = "SIGIL"
    private let appId = "666"
    private let appImageName = "SIGIL_76.png"
    private let appIconName = "SIGIL"
    #endif
    private var sdlManager: SDLManager!
    @objc static let sharedManager = ProxyManager()
    var currentHmiLevel : SDLHMILevel = .none
    
    //Vehicle Data ----------------------------------------------------/
    var subscribeVehicleData : SDLSubscribeVehicleData
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
    
    
    //Viewcontroller to send to hmi ----------------------------------------------------/
    private var _sdlVC:SDLCarWindowViewController = SDLCarWindowViewController()
    var sdlViewController:UIViewController? = blankViewController()
    var streamManager: SDLStreamingMediaManager? {
        return self.sdlManager.streamManager
    }
    
    @objc public func setStreamViewController(_ vc:UIViewController) {
        print("Changing the view controller to: \(vc.nibName ?? "IDK")")
        self.sdlManager.streamManager?.rootViewController = vc
    }
    
    
    override init() {
        subscribeVehicleData = SDLSubscribeVehicleData()
        super.init()
        
        let lifecycleConfig = SDLLifecycleConfiguration(appName: appName, fullAppId: appId)
        lifecycleConfig.appType = .navigation

        if let appImage = UIImage(named: appImageName) {
            let appIcon = SDLArtwork(image: appImage, name: appIconName, persistent: true, as: .PNG)
            lifecycleConfig.appIcon = appIcon
        }
        

        let streamingConfig = SDLStreamingMediaConfiguration(encryptionFlag: .authenticateAndEncrypt, videoSettings: nil, dataSource: self, rootViewController: self.sdlViewController)
        
        let encryptionConfig = SDLEncryptionConfiguration(securityManagers: [FMCSecurityManager.self], delegate: self)
        
        let config = SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: .enabled(), logging: .debug(), streamingMedia: streamingConfig, fileManager: .default(), encryption: encryptionConfig)
        
        streamingConfig.carWindowRenderingType = .viewAfterScreenUpdates
        
        sdlManager = SDLManager(configuration: config, delegate: self)
    }
    
    @objc func connect() {
        sdlManager?.start{ (success, error) in
            if error != nil {
                print("START UP ERROR -> \(error.debugDescription)")
            }
        }
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
    
    private func setupTemplate(type templateType: SDLPredefinedLayout, completionBlock: (() -> ())? = nil) {
        let displayTemplate = SDLSetDisplayLayout(predefinedLayout: templateType)
        self.sdlManager?.send(request: displayTemplate) { (request, response, error) in
            if response?.resultCode == .success, error == nil {
                print("The template has been set successfully")
                completionBlock?()
            } else {
                print("The template has been set unsuccessfully, \(error.debugDescription)")
            }
        }
    }
    
    private func setup() {
        setupTemplate(type: .default) { [weak self] in
            let softButton = SDLSoftButtonObject(name: "Encrypted RPC Test", state: SDLSoftButtonState(stateName: "Normal", text: "Test", image: nil), handler: { (buttonPress, buttonEvent) in
                let encryptedShow = SDLShow(mainField1: "Encrypted Hello World", mainField2: "Encrypted Test", alignment: .left)
                encryptedShow.isPayloadProtected = true
                self?.sdlManager?.send(request: encryptedShow, responseHandler: { (request, response, error) in
                    if (error != nil) {
                        print("Error sending encrypted Show request: \(error.debugDescription)")
                    } else {
                        print("Successfully sent encrypted Show request, \(String(describing: response))")
                    }
                })
            })
            self?.sdlManager?.screenManager.beginUpdates()
            self?.sdlManager?.screenManager.softButtonObjects = [softButton]
            self?.sdlManager?.screenManager.endUpdates()
        }
    }
    
}
extension ProxyManager: SDLManagerDelegate {
    func managerDidDisconnect() {
        print("Manager did disconnect")
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        print("Went from HMI level \(oldLevel) to HMI level \(newLevel)")
        currentHmiLevel = newLevel
        if (newLevel == .full ) {
            // We entered full
            print("entered HMI full")
            if(!self.isVehicleDataSubscribed){
                self.subscribeToVehicleData()
            }
        }
    }
}
extension ProxyManager: SDLStreamingMediaManagerDataSource {
    func preferredVideoFormatOrder(fromHeadUnitPreferredOrder headUnitPreferredOrder: [SDLVideoStreamingFormat]) -> [SDLVideoStreamingFormat] {
        return headUnitPreferredOrder
    }
    
    func resolution(fromHeadUnitPreferredResolution headUnitPreferredResolution: SDLImageResolution) -> [SDLImageResolution] {
        return [headUnitPreferredResolution]
    }
}
extension ProxyManager: SDLServiceEncryptionDelegate {
    func serviceEncryptionUpdated(serviceType type: SDLServiceType, isEncrypted encrypted: Bool, error: Error?) {
    }
}

//MARK: SDLAudioStreamManagerDelegate
extension ProxyManager: SDLAudioStreamManagerDelegate{
    public func audioStreamManager(_ audioManager: SDLAudioStreamManager, errorDidOccurForFile fileURL: URL, error: Error) {
        
    }
    
    public func audioStreamManager(_ audioManager: SDLAudioStreamManager, fileDidFinishPlaying fileURL: URL, successfully: Bool) {
        audioManager.playNextWhenReady()
    }
}
