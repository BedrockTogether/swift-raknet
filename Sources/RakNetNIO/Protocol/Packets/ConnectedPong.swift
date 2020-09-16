//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class ConnectedPong : Packet {
    
    var clientTime : Int64 = -1
    var serverTime : Int64 = -1

    public init(){
        super.init(PacketIdentifiers.ConnectedPong)
    }
    
    public init(_ clientTime : Int64){
        super.init(PacketIdentifiers.ConnectedPong)
        self.clientTime = clientTime
        self.serverTime = Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        clientTime = buf.readInteger(as: Int64.self)!
        if buf.readableBytes > 0 {
            serverTime = buf.readInteger(as: Int64.self)!
        }
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(clientTime, as: Int64.self)
        buf.writeInteger(serverTime, as: Int64.self)
    }
}
