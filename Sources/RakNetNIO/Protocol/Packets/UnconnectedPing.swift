//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class UnconnectedPing : OfflinePacket {
    
    var clientTime : Int64 = -1
    var clientId : Int64 = -1

    public init(){
        super.init(PacketIdentifiers.UnconnectedPing)
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        clientTime = buf.readInteger(as: Int64.self)!
        super.readMagic(&buf)
        clientId = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(clientTime, as: Int64.self)
        super.writeMagic(&buf)
        buf.writeInteger(clientId, as: Int64.self)
    }
}
