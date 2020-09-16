//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class UnconnectedPong : OfflinePacket {
    
    var clientTime : Int64 = -1
    var serverId : Int64 = -1
    var info : String = ""

    public init(){
        super.init(PacketIdentifiers.UnconnectedPong)
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        clientTime = buf.readInteger(as: Int64.self)!
        serverId = buf.readInteger(as: Int64.self)!
        super.readMagic(&buf)
        info = Packet.readString(&buf)
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(clientTime, as: Int64.self)
        buf.writeInteger(serverId, as: Int64.self)
        super.writeMagic(&buf)
        Packet.writeString(&buf, info)
    }
}
