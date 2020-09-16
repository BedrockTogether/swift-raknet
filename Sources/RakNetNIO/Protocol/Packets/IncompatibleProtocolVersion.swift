//
//  File.swift
//  
//
//  Created by Extollite on 13/09/2020.
//

import Foundation
import NIO

class IncompatibleProtocolVersion : OfflinePacket {
    
    var protocolVersion : Int32 = 0
    var serverId : Int64 = 0

    public init(){
        super.init(PacketIdentifiers.IncompatibleProtocolVersion)
    }
    
    public init(_ magic : [UInt8], _ protocolVersion : Int32,_ serverId : Int64){
        super.init(PacketIdentifiers.IncompatibleProtocolVersion)
        self.protocolVersion = protocolVersion
        self.serverId = serverId
        self.magic = magic
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        protocolVersion = Int32(buf.readInteger(as: UInt8.self)!)
        super.readMagic(&buf)
        serverId = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(UInt8(protocolVersion), as: UInt8.self)
        super.writeMagic(&buf)
        buf.writeInteger(serverId, as: Int64.self)
    }
}
