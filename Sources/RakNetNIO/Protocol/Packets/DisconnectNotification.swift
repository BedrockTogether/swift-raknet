//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class DisconnectNotification : OfflinePacket {

    public init(){
        super.init(PacketIdentifiers.DisconnectNotification)
    }
}
