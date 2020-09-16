//
//  File.swift
//  
//
//  Created by Extollite on 13/09/2020.
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
