//
//  ACK.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class ACK : AcknowledgePacket {
    
    init(){
        super.init(PacketIdentifiers.AcknowledgePacket)
    }
    
    init(_ packets : inout [UInt32], _ mtu : Int32) {
        super.init(PacketIdentifiers.AcknowledgePacket, &packets, mtu)
    }
}
