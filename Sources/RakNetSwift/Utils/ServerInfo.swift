//
//  ServerInfo.swift
//  RakNetSwift
//
//  Created by Extollite on 16/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation

public class ServerInfo {
    public var motd : String
    public var name : String
    public var protocolVersion : Int
    public var version : String
    public var currentPlayers : Int
    public var maxPlayers : Int
    public var gamemode : String
    public var serverId : Int
        
    public init(_ motd : String, _ name : String, _ protocolVersion : Int, _ version : String, _ currentPlayers : Int,
                _ maxPlayers : Int, _ gamemode : String, _ serverId : Int){
        self.motd = motd
        self.name = name
        self.protocolVersion = protocolVersion
        self.version = version
        self.currentPlayers = currentPlayers
        self.maxPlayers = maxPlayers
        self.gamemode = gamemode
        self.serverId = serverId
    }
    
    func toString() -> String {
        return "MCPE;\(self.motd);\(self.protocolVersion);\(self.version);\(self.currentPlayers);\(self.maxPlayers);\(self.serverId);\(self.name);\(self.gamemode)";
    }
}
