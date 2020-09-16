//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class OpenConnectionReply2 : OfflinePacket {
    
    var serverId : Int64 = 0
    var mtu : Int32 = 0
    var socketAddress : SocketAddress? = nil

    public init(){
        super.init(PacketIdentifiers.OpenConnectionReply2)
    }
    
    public init(_ magic : [UInt8], _ mtu : Int32, _ serverId : Int64, _ socketAddress : SocketAddress?){
        super.init(PacketIdentifiers.OpenConnectionReply2)
        self.serverId = serverId
        self.mtu = mtu
        self.socketAddress = socketAddress
        self.magic = magic
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        super.readMagic(&buf)
        serverId = buf.readInteger(as: Int64.self)!
        socketAddress = Packet.readAddress(&buf)
        mtu = Int32(buf.readInteger(as: Int16.self)!)
        buf.readInteger(as: Int8.self) //skip secure
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        super.writeMagic(&buf)
        buf.writeInteger(serverId, as: Int64.self)
        if socketAddress == nil {
            Packet.writeAddress(&buf)
        } else {
            Packet.writeAddress(&buf, socketAddress!)
        }
        buf.writeInteger(Int16(mtu), as: Int16.self)
        buf.writeInteger(0, as: Int8.self)
    }
}
