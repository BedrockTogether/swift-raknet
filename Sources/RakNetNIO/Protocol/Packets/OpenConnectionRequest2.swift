//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class OpenConnectionRequest2 : OfflinePacket {
    
    var mtu : Int32 = 0
    var clientId : Int64 = -1
    var address : SocketAddress? = nil

    public init(){
        super.init(PacketIdentifiers.OpenConnectionRequest2)
    }
    
    public init(_ magic : [UInt8], _ mtu : Int32, _ clientId : Int64, _ address : SocketAddress){
        super.init(PacketIdentifiers.OpenConnectionRequest2)
        self.mtu = mtu
        self.clientId = clientId
        self.address = address
        self.magic = magic
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        super.readMagic(&buf)
        address = Packet.readAddress(&buf)
        mtu = Int32(buf.readInteger(as: UInt16.self)!)
        clientId = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        super.writeMagic(&buf)
        Packet.writeAddress(&buf, address!)
        buf.writeInteger(Int16(mtu), as: Int16.self)
        buf.writeInteger(clientId, as: Int64.self)
    }
}
