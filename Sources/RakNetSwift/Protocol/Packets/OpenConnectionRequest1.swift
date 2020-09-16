//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class OpenConnectionRequest1 : OfflinePacket {
    
    var protocolVersion : Int32 = 0
    var mtu : Int32 = 0

    public init(){
        super.init(PacketIdentifiers.OpenConnectionRequest1)
    }
    
    public init(_ magic : [UInt8], _ protocolVersion : Int32,_ mtu : Int32){
        super.init(PacketIdentifiers.OpenConnectionRequest1)
        self.protocolVersion = protocolVersion
        self.mtu = mtu
        self.magic = magic
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        mtu = Int32(buf.readableBytes)
        super.decode(&buf)
        super.readMagic(&buf)
        protocolVersion = Int32(buf.readInteger(as: Int8.self)!)
        buf.moveReaderIndex(forwardBy: buf.readableBytes)
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        super.writeMagic(&buf)
        buf.writeInteger(UInt8(protocolVersion), as: UInt8.self)
        let length = Int(self.mtu) - buf.readableBytes
        var tempBuf = ByteBuffer.init(repeating: 0x00, count: length)
        buf.writeBuffer(&tempBuf)
    }
}
