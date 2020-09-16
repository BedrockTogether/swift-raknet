//
//  File.swift
//  
//
//  Created by Extollite on 16/09/2020.
//

import Foundation
import NIO

public protocol ConnectionListener {
    
    func onEncapsulated(_ packet : EncapsulatedPacket, _ address : SocketAddress)
    
    func onCloseConnection(_ address : SocketAddress, _ reason : String)
    
    func onOpenConnection(_ con : Connection)
    
}
