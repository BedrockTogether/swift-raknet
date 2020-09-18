//
//  ConnectionListener.swift
//  RakNetSwift
//
//  Created by Extollite on 16/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

public protocol ConnectionListener {
    
    func onEncapsulated(_ buf : ByteBuffer, _ address : SocketAddress)
    
    func onCloseConnection(_ address : SocketAddress, _ reason : String)
    
    func onOpenConnection(_ con : Connection)
    
}
