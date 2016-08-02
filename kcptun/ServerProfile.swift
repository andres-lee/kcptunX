//
//  ServerProfile.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa



class ServerProfile: NSObject {
    var uuid: String
    
    var serverHost: String = ""
    var serverPort: uint16 = 8379
    var crypt:String = "aes"
    var key:String = ""
    var remark:String = ""
    var nocomp: Bool = false
    var acknodelay: Bool = false
    var mtu: uint32 = 1350
    var mode: String = "fast"
    var conn: uint16 = 1
    var sndwnd: uint16 = 128
    var rcvwnd: uint16 = 1024
    
    override init() {
        uuid = NSUUID().UUIDString
    }
    
    init(uuid: String) {
        self.uuid = uuid
    }
    
    static func fromDictionary(data:[String:AnyObject]) -> ServerProfile {
        let cp = {
            (profile: ServerProfile) in
            profile.serverHost = data["ServerHost"] as! String
            profile.serverPort = (data["ServerPort"] as! NSNumber).unsignedShortValue
            profile.key = data["Key"] as! String
            profile.crypt = data["Crypt"] as! String
            if let nocomp = data["Nocomp"] {
                profile.nocomp = nocomp as! Bool
            }
            if let mode = data["Mode"] {
                profile.mode = mode as! String
            }
            if let mtu = data["Mtu"] {
                profile.mtu = (mtu as! NSNumber).unsignedIntValue
            }
            if let conn = data["Conn"] {
                profile.conn = (conn as! NSNumber).unsignedShortValue
            }
            if let sndwd = data["Sndwnd"] {
                profile.sndwnd = (sndwd as! NSNumber).unsignedShortValue
            }
            if let rcvwnd = data["Rcvwnd"] {
                profile.rcvwnd = (rcvwnd as! NSNumber).unsignedShortValue
            }
            if let remark = data["Remark"] {
                profile.remark = remark as! String
            }
            if let acknodelay = data["Acknodely"] {
                profile.acknodelay = acknodelay as! Bool
            }
        }
        
        if let id = data["Id"] as? String {
            let profile = ServerProfile(uuid: id)
            cp(profile)
            return profile
        } else {
            let profile = ServerProfile()
            cp(profile)
            return profile
        }
    }
    
    func toDictionary() -> [String:AnyObject] {
        var d = [String:AnyObject]()
        d["Id"] = uuid
        d["ServerHost"] = serverHost
        d["ServerPort"] = NSNumber(unsignedShort:serverPort)
        d["Mode"] = mode
        d["Key"] = key
        d["Remark"] = remark
        d["Crypt"] = crypt
        d["Nocomp"] = nocomp
        d["Acknodelay"] = acknodelay
        d["Mtu"] = NSNumber(unsignedInt: UInt32(mtu))
        d["Conn"] = NSNumber(unsignedInt: UInt32(conn))
        d["Sndwnd"] = NSNumber(unsignedInt: UInt32(sndwnd))
        d["Rcvwnd"] = NSNumber(unsignedInt: UInt32(rcvwnd))
        
        return d
    }
    
    func toJsonConfig() -> [String: AnyObject] {
        var conf: [String: AnyObject] = ["server": serverHost,
                                         "server_port": NSNumber(unsignedShort: serverPort),
                                         "key": key,
                                         "mode": mode,]
        
        let defaults = NSUserDefaults.standardUserDefaults()
        conf["local_port"] = NSNumber(unsignedShort: UInt16(defaults.integerForKey("LocalSocks5.ListenPort")))
        conf["local_address"] = defaults.stringForKey("LocalSocks5.ListenAddress")
        conf["timeout"] = NSNumber(unsignedInt: UInt32(defaults.integerForKey("LocalSocks5.Timeout")))
        conf["nocomp"] = NSNumber(bool: nocomp)
        conf["acknodelay"] = NSNumber(bool: acknodelay)
        conf["crypt"] = crypt
        conf["mtu"] = NSNumber(unsignedInt: mtu)
        conf["sndwnd"] = NSNumber(unsignedInt: UInt32(sndwnd))
        conf["rcvwnd"] = NSNumber(unsignedInt: UInt32(rcvwnd))
        conf["conn"] = NSNumber(unsignedInt: UInt32(conn))
        
        return conf
    }
    
    func isValid() -> Bool {
        func validateIpAddress(ipToValidate: String) -> Bool {
            
            var sin = sockaddr_in()
            var sin6 = sockaddr_in6()
            
            if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
                // IPv6 peer.
                return true
            }
            else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
                // IPv4 peer.
                return true
            }
            
            return false;
        }
        
        func validateDomainName(value: String) -> Bool {
            let validHostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
            
            if (value.rangeOfString(validHostnameRegex, options: .RegularExpressionSearch) != nil) {
                return true
            } else {
                return false
            }
        }
        
        if !(validateIpAddress(serverHost) || validateDomainName(serverHost)){
            return false
        }
        
        if key.isEmpty {
            return false
        }
        
        return true
    }
    
    func URL() -> NSURL? {
        let parts = "\(serverHost):\(serverPort)|\(crypt)|\(key)|\(nocomp ? 1 : 0)"
        let base64String = parts.dataUsingEncoding(NSUTF8StringEncoding)?
            .base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        if var s = base64String {
            s = s.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "="))
            return NSURL(string: "ss://\(s)")
        }
        return nil
    }
    
}
