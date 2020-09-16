//
//  File.swift
//  
//
//  Created by Extollite on 13/09/2020.
//

import Foundation
import NIO

class EncapsulatedPacket {
    var reliability : Reliability?
    var priority : Priority?
    var messageIndex : Int32? = nil
    var sequenceIndex : Int32 = 0
    var orderIndex : Int32 = 0
    var orderChannel : Int16 = 0
    var split : Bool = false
    var splitCount : Int32 = 0
    var splitId : Int32 = 0
    var splitIndex : Int32 = 0
    var buffer : ByteBuffer?
    
    var needACK = false
    var ackId : Int32 = 0
    
    func decode(_ buf : inout ByteBuffer) {
        let flags = Int32(buf.readInteger(as: Int8.self)!)
        reliability = Reliability.fromId((flags & 0b11100000) >> 5)
        split = (flags & 0b00010000) != 0
        
        let size = (buf.readInteger(as: UInt16.self)! + 7) >> 3
        
        if (reliability!.reliable) {
            messageIndex = Int32(buf.readUInt24())
        }
        
        if (reliability!.sequenced) {
            sequenceIndex = Int32(buf.readUInt24())
        }
        
        if (reliability!.ordered || reliability!.sequenced) {
            orderIndex = Int32(buf.readUInt24())
            orderChannel = Int16(buf.readInteger(as: UInt8.self)!)
        }
        
        if (split) {
            splitCount = buf.readInteger(as: Int32.self)!
            splitId = Int32(buf.readInteger(as: UInt16.self)!)
            splitIndex = buf.readInteger(as: Int32.self)!
        }
        
        buffer = buf.readSlice(length: Int(size))!
    }
    
    func encode(_ buf : inout ByteBuffer) {
        var flags = reliability!.id << Int32(5)
        
        if (split) {
            flags |= 0b00010000
        }
        buf.writeInteger(Int8(flags), as: Int8.self) // flags
        buf.writeInteger(Int16(buffer!.readableBytes << 3), as: Int16.self) // size
        
        
        if (reliability!.reliable) {
            buf.writeUInt24(UInt32(messageIndex!))
        }
        
        if (reliability!.sequenced) {
            buf.writeUInt24(UInt32(sequenceIndex))
        }
        
        if (reliability!.ordered || reliability!.sequenced) {
            buf.writeUInt24(UInt32(orderIndex))
            buf.writeInteger(UInt8(orderChannel), as: UInt8.self)
        }
        
        if (split) {
            buf.writeInteger(splitCount, as: Int32.self)
            buf.writeInteger(Int16(splitId), as: Int16.self)
            buf.writeInteger(splitIndex, as: Int32.self)
        }
        
        let bufSlice = buffer!.getBytes(at: buffer!.readerIndex, length: buffer!.readableBytes)!      // If we need to resend, we don't want the buffer's reader index changing.
        buf.writeBytes(bufSlice)
    }
    
    public func getTotalLength() -> Int32 {
        // Include back of the envelope calculation
        return 3 + self.reliability!.size + (self.split ? 10 : 0) + Int32(self.buffer!.readableBytes)
    }
}
