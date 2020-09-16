//
//  OpenConnectionReply1.swift
//  RakNetSwift
//
//  Created by Extollite on 12/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class OpenConnectionReply1 : OfflinePacket {
    
    var serverId : Int64 = 0
    var mtu : Int32 = 0

    public init(){
        super.init(PacketIdentifiers.OpenConnectionReply1)
    }
    
    public init(_ magic : [UInt8], _ mtu : Int32, _ serverId : Int64){
        super.init(PacketIdentifiers.OpenConnectionReply1)
        self.serverId = serverId
        self.mtu = mtu
        self.magic = magic
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        super.readMagic(&buf)
        serverId = buf.readInteger(as: Int64.self)!
        buf.readInteger(as: Int8.self) //skip secure
        mtu = Int32(buf.readInteger(as: Int16.self)!)
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        super.writeMagic(&buf)
        buf.writeInteger(serverId, as: Int64.self)
        buf.writeInteger(0, as: Int8.self)
        buf.writeInteger(Int16(mtu), as: Int16.self)
    }
}
