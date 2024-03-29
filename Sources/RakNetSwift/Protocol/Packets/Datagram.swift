//
//  Datagram.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class Datagram : Packet {
    
    var packets = [EncapsulatedPacket?]()
    
    var sequenceNumber : UInt32 = 0
    
    var sendTime : Int64 = -1
    
    init() {
        super.init(Flags.FLAG_VALID)
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        sequenceNumber = buf.readUInt24()
        while(buf.readableBytes > 0) {
            let packet = EncapsulatedPacket()
            packet.decode(&buf)
            packets.append(packet)
        }
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeUInt24(sequenceNumber)
        for packet in packets {
            packet!.encode(&buf)
        }
    }
    
    func length() -> Int {
        var length = 4
        for packet in packets {
            length += Int(packet!.getTotalLength())
        }
        return length
    }
    
}
