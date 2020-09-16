//
//  Packet.swift
//  RakNetSwift
//
//  Created by Extollite on 10/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class Packet {
    public var id : UInt8
    
    public init(_ id : UInt8){
        self.id = id
    }
    
    func decode(_ buf : inout ByteBuffer) {
        id = buf.readInteger(as: UInt8.self)!
    }
    
    func encode(_ buf : inout ByteBuffer) {
        buf.writeInteger(id, as: UInt8.self)
    }
    
    static func readString(_ buf : inout ByteBuffer) -> String {
        return buf.readString(length: Int(buf.readInteger(as: Int16.self)!))!
    }
    
    static func writeString(_ buf : inout ByteBuffer, _ str : String) {
        let bytes : [UInt8] = Array(str.utf8)
        buf.writeInteger(Int16(bytes.count), as: Int16.self)
        buf.writeBytes(bytes)
    }
    
    static func readAddress(_ buf : inout ByteBuffer) -> SocketAddress{
        let type = buf.readInteger(as: Int8.self)
        //var addr : [UInt8]
        var ip : String = ""
        var port : Int = 0
        
        if type == 4 {
            //let addri = ~(buf.readInteger(as: Int32.self)!)
            let ipBytes = buf.readBytes(length: 4)!
            ip = "\((-Int(ipBytes[0])-1)&0xff).\((-Int(ipBytes[1])-1)&0xff).\((-Int(ipBytes[2])-1)&0xff).\((-Int(ipBytes[3])-1)&0xff)"
            //var bufC = ByteBuffer.init(integer: addri, as: Int32.self)
            //addr = bufC.readBytes(length: bufC.readableBytes)!
            port = Int(buf.readInteger(as: UInt16.self)!)
            
            //ip = String(cString: inet_ntoa(in_addr(s_addr: in_addr_t(addri)))!)
        } else if type == 6 {
            buf.moveReaderIndex(forwardBy: 2) //family
            port = Int(buf.readInteger(as: UInt16.self)!)
            buf.moveReaderIndex(forwardBy: 4) //flow info
            let length = Int(INET6_ADDRSTRLEN) + 2
            var buffer = [CChar](repeating: 0, count: length)
            let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uint8Pointer.initialize(from: buf.readBytes(length: 16)!, count: 16)
            let hostCString = inet_ntop(AF_INET6, UnsafeRawPointer.init(uint8Pointer), &buffer, socklen_t(length))
            ip = String(cString: hostCString!)
            buf.moveReaderIndex(forwardBy: 4) //scope id
        }
        return try! SocketAddress(ipAddress: ip, port: port)
    }
    
    static func writeAddress(_ buf : inout ByteBuffer, _ address : SocketAddress ) {
        switch address {
        case .v4( _):
            Packet.writeAddress(&buf, address.ipAddress!, address.port!)
            break
        case .v6(let ipv6):
            buf.writeInteger(6, as: Int8.self)
            buf.writeInteger(10, as: Int16.self)
            buf.writeInteger(UInt16(truncatingIfNeeded: address.port!), as: UInt16.self)
            buf.writeInteger(0, as: Int32.self)
            buf.writeBytes(
                [ipv6.address.sin6_addr.__u6_addr.__u6_addr8.0,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.1,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.2,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.3,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.4,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.5,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.6,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.7,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.8,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.9,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.10,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.11,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.12,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.13,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.14,
                 ipv6.address.sin6_addr.__u6_addr.__u6_addr8.15]
            )
            buf.writeInteger(0, as: Int32.self)
            break
        case .unixDomainSocket(_): break//ignore
        }
    }
    
    static func writeAddress(_ buf : inout ByteBuffer, _ ip : String = "0.0.0.0", _ port : Int = 19132 ) {
        buf.writeInteger(4, as: Int8.self)
        //var debug = ""
        for sub in ip.split(separator: ".") {
            let number = (-Int(String(sub))! - 1)
            buf.writeInteger(UInt8(bitPattern: Int8(truncatingIfNeeded: number)), as: UInt8.self)
        }
        buf.writeInteger(UInt16(truncatingIfNeeded: port), as: UInt16.self)
    }
}
