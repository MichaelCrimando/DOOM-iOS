//
//  ProxyManager.swift
//  Doom
//
//  Created by Michael Crimando on 8/14/18.
//

import Foundation
class ProxyManager: NSObject {
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
    }
}
