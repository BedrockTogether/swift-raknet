//
//  DisconnectNotification.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class DisconnectNotification : OfflinePacket {

    public init(){
        super.init(PacketIdentifiers.DisconnectNotification)
    }
}
