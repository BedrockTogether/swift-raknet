//
//  NewIncomingConnection.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

class NewIncomingConnection : Packet {
    
    var timestamp : Int64 = 0
    var pongTimestamp : Int64 = 0
    var address : SocketAddress? = nil
    var nExtraAdresses = 0

    public init(){
        super.init(PacketIdentifiers.NewIncomingConnection)
    }
    
    public init(_ timestamp : Int64,_ pongTimestamp : Int64,_ address : SocketAddress?, _ nExtraAdresses : Int){
        super.init(PacketIdentifiers.NewIncomingConnection)
        self.timestamp = timestamp
        self.pongTimestamp = pongTimestamp
        self.address = address
        self.nExtraAdresses = nExtraAdresses
    }
    
    
    override func decode(_ buf : inout ByteBuffer) {
        super.decode(&buf)
        address = Packet.readAddress(&buf)
        nExtraAdresses = 0
        while buf.readableBytes > 16 {
            Packet.readAddress(&buf) //ignore we don't use them
            nExtraAdresses += 1
        }
        pongTimestamp = buf.readInteger(as: Int64.self)!
        timestamp = buf.readInteger(as: Int64.self)!
    }
    
    override func encode(_ buf : inout ByteBuffer) {
        super.encode(&buf)
        Packet.writeAddress(&buf, address!)
        for _ in 0..<nExtraAdresses {
            Packet.writeAddress(&buf)
        }
        buf.writeInteger(pongTimestamp, as: Int64.self)
        buf.writeInteger(timestamp, as: Int64.self)
    }
}
