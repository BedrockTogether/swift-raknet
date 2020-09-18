//
//  File.swift
//  
//
//  Created by Extollite on 14/09/2020.
//

import Foundation
import RakNetSwift
import NIO

class MyListener : ConnectionListener {
    func onEncapsulated(_ buf: ByteBuffer, _ address: SocketAddress) {
        //NOOP
    }
    
    func onCloseConnection(_ address: SocketAddress, _ reason: String) {
        //NOOP
    }
    
    func onOpenConnection(_ con: Connection) {
        //NOOP
    }
    
    
}

do {
    let listener = Listener()
    let info = ServerInfo("RakNetSwift Test", "RakNetSwift", 409, "1.16.40", 0, 5, "Creative", 0)
    var connectionListener = MyListener()
    try listener.listen(connectionListener /*yourListener*/, info)!.wait()
} catch {
    //ignore
}
