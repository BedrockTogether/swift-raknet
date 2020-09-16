//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class OfflinePacket : Packet {
    static let DEFAULT_MAGIC : [UInt8] = [
     0x00,  0xff,  0xff,  0x00,  0xfe,  0xfe,
     0xfe,  0xfe,  0xfd,  0xfd,  0xfd,  0xfd,
     0x12,  0x34,  0x56,  0x78]
    
    var magic = [UInt8]()
    
    func readMagic(_ buf : inout ByteBuffer) {
        magic = buf.readBytes(length: 16)!
    }
    
    func writeMagic(_ buf : inout ByteBuffer) {
        buf.writeBytes(OfflinePacket.DEFAULT_MAGIC)
    }
    
    func valid(_ other : [UInt8]) -> Bool {
        return magic == other
    }
}

