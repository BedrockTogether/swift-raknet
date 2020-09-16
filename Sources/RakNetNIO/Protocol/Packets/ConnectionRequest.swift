//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class ConnectionRequest : Packet {
    
    var clientId : Int64 = 0
    var timestamp : Int64 = 0

    public init(){
        super.init(PacketIdentifiers.ConnectionRequest)
    }
    
    public init(_ clientId : Int64){
        super.init(PacketIdentifiers.ConnectionRequest)
        self.clientId = clientId
        self.timestamp = Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        clientId = buf.readInteger(as: Int64.self)!
        timestamp = buf.readInteger(as: Int64.self)!
        buf.readInteger(as: Int8.self) //secure ignore
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(clientId, as: Int64.self)
        buf.writeInteger(timestamp, as: Int64.self)
        buf.writeInteger(0, as: Int8.self)
    }
}
