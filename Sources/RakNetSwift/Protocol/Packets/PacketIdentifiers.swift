//
//  PacketIdentifiers.swift
//  RakNetSwift
//
//  Created by Extollite on 10/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation

struct PacketIdentifiers {
    public static let ConnectedPing : UInt8 = 0x00
    public static let UnconnectedPing : UInt8 = 0x01
    public static let UnconnectedPong : UInt8 = 0x1c
    public static let ConnectedPong : UInt8 = 0x03
    public static let OpenConnectionRequest1 : UInt8 = 0x05
    public static let OpenConnectionReply1 : UInt8 = 0x06
    public static let OpenConnectionRequest2 : UInt8 = 0x07
    public static let OpenConnectionReply2 : UInt8 = 0x08
    public static let ConnectionRequest : UInt8 = 0x09
    public static let ConnectionRequestAccepted : UInt8 = 0x10
    public static let NewIncomingConnection : UInt8 = 0x13
    public static let DisconnectNotification : UInt8 = 0x15
    public static let IncompatibleProtocolVersion : UInt8 = 0x19

    public static let AcknowledgePacket : UInt8 = 0xc0
    public static let NacknowledgePacket : UInt8 = 0xa0

}
