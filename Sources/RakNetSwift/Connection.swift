//
//  Connection.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

public class Connection {
    
    var listener : Listener?
    var mtu : Int32 = 0
    public var address : SocketAddress?
    
    var state : State = .CONNECTING //client connection state
    
    var nackQueue = [UInt32]() // Queue containing sequence ids of packets not received
    var ackQueue = [UInt32]() // Queue containing sequence numbers to let know the game packets we sent
    
    var sendDatagrams = [Int32 : Datagram]() // we store packets if they will need resending
    
    //TODO: Packet Weights
    //var outgoingPackets = [Datagram?]() //packets to send
    
    var outgoingPacket = Datagram() // current datagram to send
    
    var splitPacket = [Int32 : [Int32 : EncapsulatedPacket]]() //recived splitted packets that we will be reassembled
    
    var windowStart : Int32 = -1
    var windowEnd : Int32 = 2048
    var reliableWindowStart : Int32 = 0
    var reliableWindowEnd : Int32 = 2048
    var reliableWindow = [Int32 : EncapsulatedPacket]()
    var lastReliableIndex : Int32 = -1
    
    var recievedWindow = [Int32]()
    
    var lastSequenceNumber : Int32 = -1
    var sendSequenceNumber : Int32 = 0
    
    var messageIndex : Int32 = -1
    
    var channelIndex = [Int32]()
    
    var needACK = [Int32 : Int32?]()
    
    var splitId : Int32 = 0
    
    var lastUpdate : Int64 = Int64(NSDate().timeIntervalSince1970 * 1000)
        
    var isActive = false
    
    init(_ listener : Listener, _ mtu : Int32, _ address : SocketAddress){
        self.listener = listener
        self.mtu = mtu
        self.address = address
        
        self.lastUpdate = Int64(NSDate().timeIntervalSince1970 * 1000)
        
        for _ in 0..<32 {
            self.channelIndex.append(0)
        }
    }
    
    func update(_ timestamp : Int64 ) {
        if(!self.isActive && (self.lastUpdate + 10000) < timestamp){
            self.disconnect("timeout")
            return
        }
        
        self.isActive = false
        
        if(self.ackQueue.count > 0){
            let pk = ACK(&self.ackQueue, Int32(self.mtu - 5))
            var buf = self.listener!.channel!.allocator.buffer(capacity: Int(self.mtu - 4))
            //print("ack: \(self.ackQueue)")
            pk.encode(&buf)
            self.sendPacket(&buf)
        }
        
        if(self.nackQueue.count > 0){
            let pk = NACK(&self.nackQueue, Int32(self.mtu - 5))
            var buf = self.listener!.channel!.allocator.buffer(capacity: Int(self.mtu - 4))
            //print("nack: \(self.ackQueue)")
            pk.encode(&buf)
            self.sendPacket(&buf)
        }
        
//        if(self.outgoingPackets.count > 0){
//            var limit = 16
//            var size = self.outgoingPackets.count
//            while size > 0 {
//                let packet = self.outgoingPackets[0]
//                packet!.sendTime = timestamp
//                self.sendDatagrams[Int32(packet!.sequenceNumber)] = packet
//                self.outgoingPackets.dropFirst()
//
//                size -= 1
//                limit -= 1
//
//                if(limit <= 0){
//                    break
//                }
//            }
//
//            if(self.outgoingPackets.count > 2048){
//                self.outgoingPackets = []
//            }
//        }
        
        for (seq, pk) in self.sendDatagrams {
            let temp = self.outgoingPacket
            if pk.sendTime < (Int64(NSDate().timeIntervalSince1970 * 1000) - 8) {
//                self.outgoingPackets.append(pk)
                self.outgoingPacket = pk
                self.sendQueue()
                self.sendDatagrams[seq] = nil
            }
            self.outgoingPacket = temp
        }
        
        var size = self.recievedWindow.count
        while size > 0 {
            if self.recievedWindow[0] < self.windowStart {
                self.recievedWindow.dropFirst()
                size -= 1
            } else {
                break
            }
        }
        
        self.sendQueue()
    }
    
    func recieve(_ buf : inout ByteBuffer){
        self.isActive = true
        self.lastUpdate = Int64(NSDate().timeIntervalSince1970 * 1000)
        let header = buf.readInteger(as: UInt8.self)!
        buf.moveReaderIndex(to: 0)
        let datagram = (header & Flags.FLAG_VALID) != 0
        print("id: \(header)")
        if datagram {
            if (header & Flags.FLAG_ACK) != 0 {
                //print("ack")
                self.handleACK(&buf)
            } else if (header & Flags.FLAG_NACK) != 0 {
                //print("nack")
                self.handleNACK(&buf)
            } else {
                //print("datagram")
                self.handleDatagram(&buf)
            }
        } else {
            //print("else")
            if(header < 0x80) {
                if(self.state == State.CONNECTING) {
                    if(header == PacketIdentifiers.ConnectionRequest){
                        let pk = ConnectionRequest()
                        pk.decode(&buf)
                        
                        let accept = ConnectionRequestAccepted(self.address, pk.timestamp)
                        let ipv6 = self.address!.protocol == .inet6
                        
                        var buf = self.listener!.channel!.allocator.buffer(capacity: ipv6 ? 628 : 166)
                        
                        accept.encode(&buf)
                        
                        let sendPk = EncapsulatedPacket()
                        sendPk.reliability = Reliability.UNRELIABLE
                        sendPk.buffer = buf
                        self.addToQueue(sendPk, Priority.IMMEDIATE)
                    } else if(header == PacketIdentifiers.NewIncomingConnection) {
                        let pk = NewIncomingConnection()
                        pk.decode(&buf)
                        
                        let port = self.address!.port!
                        if pk.address!.port! == port {
                            self.state = .CONNECTED
                            self.listener!.connectionListener!.onOpenConnection(self)
                        }
                    }
                }
            }
        }
    }
    
    func handleACK(_ buf : inout ByteBuffer){
        let packet = ACK()
        packet.decode(&buf)
        for seq in packet.packets {
            for i in seq.start...seq.end {
                //print("ackSeq: \(i)")
                if self.sendDatagrams[Int32(i)] != nil {
                    for pk in self.sendDatagrams[Int32(i)]!.packets {
                        if pk != nil && pk!.needACK && pk!.messageIndex != -1 {
                            self.needACK[pk!.ackId] = nil
                        }
                    }
                    self.sendDatagrams[Int32(i)] = nil
                }
            }
            
        }
    }
    
    func handleNACK(_ buf : inout ByteBuffer){
        let pk = NACK()
        pk.decode(&buf)
        let temp = self.outgoingPacket
        for seq in pk.packets {
            for i in seq.start...seq.end {
                if self.sendDatagrams[Int32(i)] != nil {
                    self.outgoingPacket = self.sendDatagrams[Int32(i)]!
                    self.sendQueue()
                    //self.outgoingPackets.append(packet)
                    self.sendDatagrams[Int32(i)] = nil
                }
            }
        }
        self.outgoingPacket = temp
    }
    
    func handleDatagram(_ buf : inout ByteBuffer){
        let packet = Datagram()
        packet.decode(&buf)
        if(packet.sequenceNumber < self.windowStart || packet.sequenceNumber > self.windowEnd || self.recievedWindow.contains(Int32(packet.sequenceNumber))) {
            return
        }
        
        // Check if there are missing packets between the received packet and the last received one
        let diff = Int32(packet.sequenceNumber) - self.lastSequenceNumber
        
        // Check if the packet was a missing one, so in the nack queue
        // if it was missing, remove from the queue because we received it now
        let index = self.nackQueue.firstIndex(of: packet.sequenceNumber)
        if index != nil {
            self.nackQueue.remove(at: index!)
        }
        
        // Add the packet to the ack queue
        // to let know client we get the packet
        self.ackQueue.append(packet.sequenceNumber)
        
        // Add the packet to the received window, a property that keeps
        // all the sequence numbers of packets we received
        // if we mark packet as lost and then recive original one and copy
        // we won't decode copy
        self.recievedWindow.append(Int32(packet.sequenceNumber))
        
        // Check if the sequence is broken
        if(diff != 1) {
            for i in (self.lastSequenceNumber + 1)..<Int32(packet.sequenceNumber) {
                // Mark the packet sequence number as lost
                // so client will resend it
                if !self.recievedWindow.contains(i) {
                    self.nackQueue.append(UInt32(i))
                }
            }
        }
        
        if(diff >= 1) {
            self.lastSequenceNumber = Int32(packet.sequenceNumber)
            self.windowStart += diff
            self.windowEnd += diff
        }
        
        for pk in packet.packets {
            if(pk != nil) {
                self.recievePacket(pk!)
            }
        }
    }
    
    func recievePacket(_ pk : EncapsulatedPacket){
        if(pk.messageIndex == nil){
            self.handlePacket(pk)
        } else {
            if(pk.messageIndex! < self.reliableWindowStart || pk.messageIndex! > self.reliableWindowEnd) {
                return
            }
            
            if(pk.messageIndex! - self.lastReliableIndex == 1){
                self.lastReliableIndex += 1
                self.reliableWindowStart += 1
                self.reliableWindowEnd += 1
                self.handlePacket(pk)
                
                if(self.reliableWindow.count > 0) {
                    let windows = self.reliableWindow.sorted(by: { $0.0 < $1.0 })
                    var newReliableWindow = [Int32 : EncapsulatedPacket]()
                    
                    for el in windows {
                        newReliableWindow[el.key] = el.value
                    }
                    
                    self.reliableWindow = newReliableWindow
                    
                    for (seq, packet) in self.reliableWindow {
                        if (seq - self.lastReliableIndex) != 1 {
                            break
                        }
                        self.lastReliableIndex += 1
                        self.reliableWindowStart += 1
                        self.reliableWindowEnd += 1
                        
                        self.handlePacket(packet)
                        
                        self.reliableWindow[seq] = nil
                    }
                }
            } else {
                self.reliableWindow[pk.messageIndex!] = pk
            }
        }
    }
    
    func handlePacket(_ packet : EncapsulatedPacket) {
        if(packet.split){
            self.handleSplit(packet)
            return
        }
        
        let id = packet.buffer!.readInteger(as: UInt8.self)!
        print("packet: \(id)")
        packet.buffer!.moveReaderIndex(to: 0)
        if(id < 0x80) {
            if(self.state == State.CONNECTING) {
                if(id == PacketIdentifiers.ConnectionRequest){
                    let pk = ConnectionRequest()
                    pk.decode(&packet.buffer!)
                    
                    let accept = ConnectionRequestAccepted(self.address, pk.timestamp)
                    let ipv6 = self.address!.protocol == .inet6
                    var buf = self.listener!.channel!.allocator.buffer(capacity: (ipv6 ? 628 : 166))
                    
                    accept.encode(&buf)
                    let sendPk = EncapsulatedPacket()
                    sendPk.reliability = Reliability.UNRELIABLE
                    sendPk.buffer = buf
                    self.addToQueue(sendPk, Priority.IMMEDIATE)
                } else if(id == PacketIdentifiers.NewIncomingConnection) {
                    let pk = NewIncomingConnection()
                    pk.decode(&packet.buffer!)
                    
                    let port = self.listener!.channel!.localAddress!.port!
                    if pk.address!.port! == port {
                        //print("connected \(self.address!)")
                        self.state = .CONNECTED
                        self.listener!.connectionListener!.onOpenConnection(self)
                    }
                }
            } else if id == PacketIdentifiers.DisconnectNotification {
                self.disconnect("client disconnect")
            } else if id == PacketIdentifiers.ConnectedPing {
                let pk = ConnectedPing()
                pk.decode(&packet.buffer!)
                
                let pong = ConnectedPong(pk.clientTime)
                var buf = self.listener!.channel!.allocator.buffer(capacity: 17)
                pong.encode(&buf)
                
                let sendPk = EncapsulatedPacket()
                sendPk.reliability = Reliability.UNRELIABLE
                sendPk.buffer = buf
                self.addToQueue(sendPk, Priority.IMMEDIATE)
            }
        } else if self.state == .CONNECTED {
            //print("con: \(id)")
            self.listener!.connectionListener!.onEncapsulated(packet.buffer!, self.address!)
        }
    }
    
    func addEncapsulatedToQueue(_ packet : EncapsulatedPacket, _ flags : Priority = .NORMAL) {
        packet.needACK = ((flags.rawValue & 0b00001000) > 0)
        if packet.needACK {
            self.needACK[packet.ackId] = nil
        }

        if (packet.reliability!.id >= 2)
        {
            self.messageIndex += 1
            packet.messageIndex! = self.messageIndex

            if (packet.reliability! == Reliability.RELIABLE_ORDERED) {
                packet.orderIndex = self.channelIndex[Int(packet.orderChannel)]
                self.channelIndex[Int(packet.orderChannel)] += 1
            }
            
        }

        if (packet.getTotalLength() + 4 > self.mtu) {
            // Split the buffer into chunks
            var buffers = [ByteBuffer]()
            let maxLength = self.mtu - 28 - 4 - 2
            let split = ((packet.buffer!.readableBytes - 1) / Int(maxLength)) + 1
            for _ in 0..<split {
                buffers.append(packet.buffer!.readSlice(length: min(Int(maxLength), packet.buffer!.readableBytes))!)
            }
            self.splitId += 1
            let splitID = self.splitId % 65536
            for i in 0..<buffers.count {
                let pk = EncapsulatedPacket()
                pk.splitId = splitID
                pk.split = true
                pk.splitCount = Int32(buffers.count)
                pk.reliability = packet.reliability
                pk.splitIndex = Int32(i)
                pk.buffer = buffers[i]
                if (buffers.count > 0) {
                    self.messageIndex += 1
                    pk.messageIndex = self.messageIndex
                } else {
                    pk.messageIndex = packet.messageIndex
                }
                if (pk.reliability == Reliability.RELIABLE_ORDERED) {
                    pk.orderChannel = packet.orderChannel
                    pk.orderIndex = packet.orderIndex
                }
                self.addToQueue(pk, Priority(rawValue: flags.rawValue | Priority.IMMEDIATE.rawValue)!)
            }
        } else {
            self.addToQueue(packet, flags)
        }
    }
    
    public func sendDataPacket(_ buf : inout ByteBuffer){
        let packet = EncapsulatedPacket()
        packet.reliability = Reliability.UNRELIABLE
        packet.buffer = buf
        self.addEncapsulatedToQueue(packet)
    }
    
    public func sendDataPacketImmediately(_ buf : inout ByteBuffer){
        let packet = EncapsulatedPacket()
        packet.reliability = Reliability.UNRELIABLE
        packet.buffer = buf
        self.addEncapsulatedToQueue(packet, Priority.IMMEDIATE)
    }
    
    func addToQueue(_ packet : EncapsulatedPacket, _ flags : Priority = .NORMAL) {
        let priority = flags.rawValue & 0b0000111
        if packet.needACK && packet.messageIndex != nil {
            self.needACK[packet.ackId] = packet.messageIndex
        }
        
        if priority == Priority.IMMEDIATE.rawValue {
            let pk = Datagram()
            pk.sequenceNumber = UInt32(self.sendSequenceNumber)
            self.sendSequenceNumber += 1
            pk.packets.append(packet)
            if (packet.needACK) {
                packet.needACK = false
            }
            
            var buf = self.listener!.channel!.allocator.buffer(capacity: Int(pk.length()))
            pk.encode(&buf)
            pk.sendTime = Int64(NSDate().timeIntervalSince1970 * 1000)
            self.sendPacket(&buf)
            self.sendDatagrams[Int32(pk.sequenceNumber)] = pk
            return
        }
        
        let length = self.outgoingPacket.length()
        if Int32(length) + packet.getTotalLength() > self.mtu {
            self.sendQueue()
        }
        
        self.outgoingPacket.packets.append(packet)
        
        if(packet.needACK){
            packet.needACK = false
        }
    }
    
    func handleSplit(_ packet : EncapsulatedPacket) {
        if(self.splitPacket[packet.splitId] != nil){
            var value = self.splitPacket[packet.splitId]
            value![packet.splitIndex] = packet
            self.splitPacket[packet.splitId] = value
        } else {
            self.splitPacket[packet.splitId] = [packet.splitIndex : packet]
        }
        
        let localSplits = self.splitPacket[packet.splitId]
        if(localSplits!.count == packet.splitCount){
            let pk = EncapsulatedPacket()
            
            // pk.reliability = packet.reliability
            // pk.messageIndex = packet.messageIndex
            // pk.sequenceIndex = packet.sequenceIndex
            // pk.orderIndex = packet.orderIndex
            // pk.orderChannel = packet.orderChannel
            
            var sz = 0
            for netPacket in localSplits! {
                sz += netPacket.value.buffer!.readableBytes
            }
            
            var buf = self.listener!.channel!.allocator.buffer(capacity: sz)
            for pk in localSplits!.sorted(by: { $0.0 < $1.0 }) {
                var pkBuf = pk.value.buffer!
                buf.writeBytes(pkBuf.readBytes(length: pkBuf.readableBytes)!)
            }
            
            self.splitPacket[packet.splitId] = nil
            
            pk.buffer = buf
            
            self.recievePacket(pk)
        }
    }
    
    func disconnect(_ reason : String = "unknown") {
        self.listener!.removeConnection(self, reason)
    }
    
    func sendQueue() {
        if (self.outgoingPacket.packets.count > 0) {
            self.sendSequenceNumber += 1
            self.outgoingPacket.sequenceNumber = UInt32(self.sendSequenceNumber)
            var buf = ByteBufferAllocator.init().buffer(capacity: self.outgoingPacket.length())
            self.outgoingPacket.encode(&buf)
            self.sendPacket(&buf)
            self.outgoingPacket.sendTime = Int64(NSDate().timeIntervalSince1970 * 1000)
            self.sendDatagrams[Int32(self.outgoingPacket.sequenceNumber)] = self.outgoingPacket
            self.outgoingPacket = Datagram()
        }
    }
    
    func sendPacket(_ buf : inout ByteBuffer) {
        self.listener!.sendBuffer(&buf, self.address!)
    }
    
    func close() {
        var buf = self.listener!.channel!.allocator.buffer(bytes: [0x00, 0x00, 0x08, 0x15])
        let pk = EncapsulatedPacket()
        pk.decode(&buf)
        self.addEncapsulatedToQueue(pk)
    }
}
