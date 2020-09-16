//
//  File.swift
//  
//
//  Created by Extollite on 10/09/2020.
//

import Foundation

public struct Flags {
    public static let FLAG_VALID : UInt8 = 0b10000000
    public static let FLAG_ACK : UInt8 = 0b01000000
    public static let FLAG_HAS_B_AND_AS : UInt8 = 0b00100000
    public static let FLAG_NACK : UInt8 = 0b00100000
    public static let FLAG_PACKET_PAIR : UInt8 = 0b00010000
    public static let FLAG_CONTINUOUS_SEND : UInt8 = 0b00001000
    public static let FLAG_NEEDS_B_AND_AS : UInt8 = 0b00000100
}
