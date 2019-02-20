//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

// Swift migration notice: this protocol conforms to NSObjectProtocol only to be usable from Obj-C.
@objc public protocol BackendEnvironmentProvider: NSObjectProtocol {
    /// Backend base URL.
    var backendURL: URL { get }
    /// URL for SSL WebSocket connection.
    var backendWSURL: URL { get }
    /// URL for version blacklist file.
    var blackListURL: URL { get }
    /// Frontent URL, used to open the necessary web resources, like password reset.
    var frontendURL: URL { get }
    
    var momentURL: URL {get}
    
    var appLetsURL:URL {get}
}

// Swift migration notice: this class conforms to NSObject only to be usable from Obj-C.
public class CustomBackend: NSObject, BackendEnvironmentProvider {
    public let backendURL: URL
    public let backendWSURL: URL
    public let blackListURL: URL
    public let frontendURL: URL
    public let momentURL: URL
    public let appLetsURL: URL
    
    public init(backendURL: URL, backendWSURL: URL, blackListURL: URL, frontendURL: URL, momentURL: URL, appLetsURL: URL) {
        self.backendURL   = backendURL
        self.backendWSURL = backendWSURL
        self.blackListURL = blackListURL
        self.frontendURL  = frontendURL
        self.momentURL = momentURL
        self.appLetsURL = appLetsURL
        
        super.init()
    }
    
    public override var debugDescription: String {
        return "CustomBackend: \(backendURL) \(backendWSURL) \(blackListURL) \(frontendURL)"
    }
}

@objc public enum WireEnvironmentType: Int {
    case production
    case staging
}

extension WireEnvironmentType {
    init(userDefaultsValue: String) {
        switch userDefaultsValue {
        case "staging":
            self = .staging
        case "production", "default":
            fallthrough
        default:
            self = .production
        }
    }
}

public enum BackendEnvironmentType {
    case wire(WireEnvironmentType)
    case custom(CustomBackend)
}

// Swift migration notice: this class conforms to NSObject only to be usable from Obj-C.
@objcMembers
public class BackendEnvironment: NSObject, BackendEnvironmentProvider {
    public let type: BackendEnvironmentType
    
    public let backendURL: URL
    public let backendWSURL: URL
    public let blackListURL: URL
    public let frontendURL: URL
    public let momentURL: URL
    public let appLetsURL:URL
    
    
    @objc public init(wireEnvironment: WireEnvironmentType) {
        type = .wire(wireEnvironment)
        switch wireEnvironment {
        case .production:
            self.backendURL   = URL(string: "https://account.isecret.im")!
            self.backendWSURL = URL(string: "https://account.isecret.im")!
            self.blackListURL = URL(string: "https://account.isecret.im/prod/ios")!
            self.frontendURL  = URL(string: "https://account.isecret.im")!
            self.momentURL = URL(string: "https://m.isecret.im")!
            self.appLetsURL = URL(string: "https://cloud.isecret.im")!
            
        case .staging:
            self.backendURL   = URL(string: "https://accounttest.isecret.im")!
            self.backendWSURL = URL(string: "https://accounttest.isecret.im")!
            self.blackListURL = URL(string: "https://accounttest.isecret.im/prod/ios")!
            self.frontendURL  = URL(string: "https://accounttest.isecret.im")!
            self.momentURL = URL(string: "https://testm.pichat.im")!
            self.appLetsURL = URL(string: "https://testm.pichat.im")!
        }
        super.init()
    }
    
    public init(customBackend: CustomBackend) {
        type = .custom(customBackend)
        self.backendURL   = customBackend.backendURL
        self.backendWSURL = customBackend.backendWSURL
        self.blackListURL = customBackend.blackListURL
        self.frontendURL  = customBackend.frontendURL
        self.momentURL = customBackend.momentURL
        self.appLetsURL = customBackend.appLetsURL
        
        super.init()
    }
    
    public convenience init(type: BackendEnvironmentType) {
        switch type {
        case .custom(let custom):
            self.init(customBackend: custom)
        case .wire(let wireEnvironment):
            self.init(wireEnvironment: wireEnvironment)
        }
    }
    
    public convenience init(userDefaults: UserDefaults) {
        guard let currentSetting = userDefaults.string(forKey: "ZMBackendEnvironmentType") else {
            self.init(wireEnvironment: .production)
            return
        }
        
        self.init(wireEnvironment: WireEnvironmentType(userDefaultsValue: currentSetting))
    }
    
    public override var debugDescription: String {
        return "BackendEnvironment: type \(type.debugDescription)"
    }
}

extension WireEnvironmentType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .production:
            return "WireEnvironmentType: production"
        case .staging:
            return "WireEnvironmentType: staging"
        }
    }
}

extension BackendEnvironmentType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .custom(let customBackend):
            return "BackendEnvironmentType: custom (\(customBackend.debugDescription))"
        case .wire(let wireEnvironment):
            return "BackendEnvironmentType: wire (\(wireEnvironment.debugDescription))"
        }
    }
}
