//
//  File.swift
//  
//
//  Created by Extollite on 12/09/2020.
//

import Foundation
import NIO

class ConnectedPing : Packet {
    
    var clientTime : Int64 = -1

    public init(){
        super.init(PacketIdentifiers.ConnectedPing)
    }
    
    public init(_ clientTime : Int64){
        super.init(PacketIdentifiers.ConnectedPing)
        self.clientTime = clientTime
    }
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        clientTime = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        buf.writeInteger(clientTime, as: Int64.self)
    }
    
    public static func newReliablePing() -> ConnectedPing {
        let out = ConnectedPing()
        return out
    }
}
