//
//  ProxyManager.swift
//  DOOM
//
//  Created by Michael Crimando on 3/18/20.
//
import Foundation
import SmartDeviceLink

class ProxyManager: NSObject {
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
    private let appName = "DOOM"
    private let appId = "666"
    private let appImageName = "SIGIL_76.png"
    #endif
    private var sdlManager: SDLManager!
    @objc static let sharedManager = ProxyManager()
    
    //viewcontroller to send to hmi
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
        super.init()
        
        let lifecycleConfig = SDLLifecycleConfiguration(appName: appName, fullAppId: appId)
        lifecycleConfig.appType = .navigation
        

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
        switch (oldLevel, newLevel) {
        case (.none, .full):
            break
        default:
            break
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
