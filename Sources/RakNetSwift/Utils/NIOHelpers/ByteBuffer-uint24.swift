//
//  ByteBuffer-uint24.swift
//  RakNetSwift
//
//  Created by Extollite on 16/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

extension ByteBuffer {
    
    @discardableResult
    @inlinable
    public mutating func writeUInt24(_ value : UInt32) -> Int{
        self.writeInteger(UInt8(truncatingIfNeeded: value))
        self.writeInteger(UInt8(truncatingIfNeeded: value >> 8))
        self.writeInteger(UInt8(truncatingIfNeeded: value >> 16))
        return Int(3)
    }
    
    @inlinable
    public mutating func readUInt24() -> UInt32{
        let ba : UInt8 = self.readInteger(as: UInt8.self)!
        let bb : UInt8 = self.readInteger(as: UInt8.self)!
        let bc : UInt8 = self.readInteger(as: UInt8.self)!
        var ret = UInt32(ba)
        ret |= UInt32(bb) << 8
        ret |= UInt32(bc) << 16
        return ret
    }
}
