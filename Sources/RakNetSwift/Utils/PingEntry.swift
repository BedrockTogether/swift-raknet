//
//  File.swift
//  
//
//  Created by Extollite on 11/11/2022.
//

import Foundation
import NIO

class PingEntry {
    public let promise: EventLoopPromise<ServerInfo>
    public let timeout: Int
    public var sendTime: Int
    
    init(_ promise: EventLoopPromise<ServerInfo>, _ timeout: Int, _ sendTime: Int) {
        self.promise = promise
        self.timeout = timeout
        self.sendTime = sendTime
    }
}
