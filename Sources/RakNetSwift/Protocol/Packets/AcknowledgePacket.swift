//
//  AcknowledgePacket.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class AcknowledgePacket : Packet {
    
    var packets : [Entry]
    
    var mtu : Int32
    
    override init(_ id : UInt8){
        self.packets = []
        self.mtu = 0
        super.init(id)
    }
    
    init(_ id : UInt8, _ packets : inout [UInt32], _ mtu : Int32){
        packets.sort {
            $0 < $1
        }
        
        self.packets = []
        self.mtu = mtu
        
        if packets.count > 0 {
            var i = 1
            var firstIndex = 0
            var start = packets[0]
            var end = packets[0]
            
            while i < packets.count {
                let current = packets[i]
                i += 1
                let length = current - end
                if length == 1 {
                    end = current
                } else if length > 1 {
                    if(start == end){
                        if(self.mtu < 4){
                            break
                        }
                        self.mtu -= 4
                    } else {
                        if(self.mtu < 7) {
                            break
                        }
                        self.mtu -= 7
                    }
                    self.packets.append(Entry(start, end))
                    start = current
                    end = current
                    firstIndex = i
                }
            }
            if(start == end){
                if(self.mtu >= 4) {
                    self.packets.append(Entry(start))
                    self.mtu -= 4
                }
                firstIndex = i
                //self.packets.append(Entry(start))
            } else if(start != end){
                if(self.mtu >= 7){
                    self.packets.append(Entry(start, end))
                    self.mtu -= 7
                }
                firstIndex = i
                //self.packets.append(Entry(start, end))
            }
            if(self.packets.count > 0){
                packets.removeFirst(firstIndex)
            }
        }
        super.init(id)
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        packets = []
        let recordCount = buf.readInteger(as: Int16.self)!
        for _ in 0..<recordCount {
            let recordType = buf.readInteger(as: Int8.self)!
            if recordType == 0 {
                let start = buf.readUInt24()
                let end = buf.readUInt24()
                packets.append(Entry(start, end))
            } else {
                let start = buf.readUInt24()
                packets.append(Entry(start))
            }
        }
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(UInt16(self.packets.count), as: UInt16.self)
        for entry in self.packets {
            if(entry.start == entry.end){
                buf.writeInteger(1, as: UInt8.self)
                buf.writeUInt24(entry.start)
            } else {
                buf.writeInteger(0, as: UInt8.self)
                buf.writeUInt24(entry.start)
                buf.writeUInt24(entry.end)
            }
        }
    }
    
    
    class Entry : Comparable {
        let start : UInt32
        let end : UInt32
        
        convenience init(_ start : UInt32){
            self.init(start, start)
        }
        
        init(_ start : UInt32, _ end : UInt32){
            self.start = start
            self.end = end
        }
        
        static func < (lhs: AcknowledgePacket.Entry, rhs: AcknowledgePacket.Entry) -> Bool {
            return lhs.start < rhs.start
        }
        
        static func == (lhs: AcknowledgePacket.Entry, rhs: AcknowledgePacket.Entry) -> Bool {
            return lhs.start == rhs.start && lhs.end == rhs.end
        }
    }
}

