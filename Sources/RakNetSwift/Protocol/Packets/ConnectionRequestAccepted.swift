//
//  File.swift
//  
//
//  Created by Extollite on 13/09/2020.
//

import Foundation
import NIO

class ConnectionRequestAccepted : Packet {
    
    var address : SocketAddress? = nil
    var timestamp : Int64 = 0
    var nExtraAdresses = 0

    public init(){
        super.init(PacketIdentifiers.ConnectionRequestAccepted)
    }
    
    public convenience init(_ address : SocketAddress?,_ timestamp : Int64){
        self.init(address, timestamp, 20)
    }
    
    public init(_ address : SocketAddress?,_ timestamp : Int64, _ nExtraAdresses : Int){
        super.init(PacketIdentifiers.ConnectionRequestAccepted)
        self.address = address
        self.timestamp = timestamp
        self.nExtraAdresses = nExtraAdresses
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        address = Packet.readAddress(&buf)
        buf.readInteger(as: Int16.self) // system index
        nExtraAdresses = 20
        for _ in 0..<20 {
            Packet.readAddress(&buf) //ignore we don't use them
            //nExtraAdresses += 1
        }
        timestamp = buf.readInteger(as: Int64.self)!
        timestamp = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        Packet.writeAddress(&buf, address!)
        buf.writeInteger(0, as: Int16.self)
        Packet.writeAddress(&buf, "127.0.0.1")
        for _ in 1..<nExtraAdresses {
            Packet.writeAddress(&buf)
        }
        buf.writeInteger(timestamp, as: Int64.self)
        buf.writeInteger(Int64(NSDate().timeIntervalSince1970 * 1000), as: Int64.self)
    }
}
