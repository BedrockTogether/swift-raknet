//
//  ConnectionListener.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

// Minecraft related protocol
let PROTOCOL = 11

// Raknet ticks
let RAKNET_TPS = 100
let RAKNET_TICK_LENGTH = 1.0 / Double(RAKNET_TPS)

public class Listener {
    struct StandardOutput : Printer {
        func print(_ msg: String) {
            Swift.print(msg)
        }
    }
    
    var id = Int64(arc4random()) &+ (Int64(arc4random()) << 32)
    
    var info : ServerInfo?
    
    var channel : Channel?
    
    public var connections = [SocketAddress : Connection]()
    
    var shutdown = false
        
    var connectionListener : ConnectionListener?
    
    public var printer : Printer = StandardOutput()
    
    var updateTask : RepeatedTask?
    
    var group : EventLoopGroup?
    
    public var allocator : ByteBufferAllocator {
        get {
            return self.channel!.allocator
        }
    }
    
    public init(){
        
    }
    
    public func listen<T : ConnectionListener>(_ connectionListener : T?, _ serverInfo : ServerInfo, _ host : String = "0.0.0.0", _ port : Int = 19132, _ group : EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)) -> EventLoopFuture<Void>? {
        serverInfo.serverId = Int(id)
        self.info = serverInfo
        self.connectionListener = connectionListener
        self.group = group
        var bootstrap = DatagramBootstrap(group: group).channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            
            // Set the handlers that are applied to the bound channel
            .channelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(ServerDatagramHandler(self), position: .last)
            }
        
        do {
            channel = try bootstrap.bind(host: host, port: port).wait()
        } catch NIO.SocketAddressError.unknown(host: host, port: port) {
            self.printer.print("unavaliable: \(host) \(port)")
            return nil
        } catch {
            self.printer.print(error.localizedDescription)
            return nil
        }
        
        self.tick()
        
        //self.printer.print("Server started and listening on \(channel!.localAddress!)")
        
        return channel!.closeFuture
    }
    
    deinit {
        //self.printer.print("Deinit")
        for con in self.connections {
            self.removeConnection(con.value, "shutdown")
        }
    }
    
    public func close(){
        self.shutdown = true
        if channel != nil {
            channel!.close()
        }
    }
    
    func tick() {
        //        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".timer")
        //        timer = DispatchSource.makeTimerSource(queue: queue)
        //        timer!.schedule(deadline: .now(), repeating: .milliseconds(Int(RAKNET_TICK_LENGTH * 1000)))
        //        timer!.setEventHandler { [weak self] in
        //            do {
        //                try self!.channel!.eventLoop.next().submit {
        //                    if(!self!.shutdown) {
        //                        for con in self!.connections {
        //                            con.value.update(Int64(NSDate().timeIntervalSince1970 * 1000))
        //                        }
        //                    } else {
        //                        self!.timer?.cancel()
        //                        self!.timer = nil
        //                    }
        //                }.wait()
        //            } catch {
        //                self!.printer.print("\(error.localizedDescription)")
        //            }
        //
        //        }
        //        timer!.resume()
                
        updateTask = channel!.eventLoop.next().scheduleRepeatedTask(initialDelay: TimeAmount.milliseconds(0), delay: TimeAmount.milliseconds(Int64(RAKNET_TICK_LENGTH * 1000)), {
            repeatedTask in
            if(!self.shutdown) {
                //self.printer.print("Tick")
                for con in self.connections {
                    con.value.update(Int64(NSDate().timeIntervalSince1970 * 1000))
                }
            } else {
                repeatedTask.cancel()
            }
        })
    }
    
    public func sendBuffer(_ buffer : inout ByteBuffer, _ address : SocketAddress) {
        self.channel!.writeAndFlush(AddressedEnvelope(remoteAddress: address, data: buffer))
    }
    
    public func removeConnection(_ connection : Connection, _ reason : String) {
        if !shutdown {
            self.channel!.eventLoop.next().submit {
                let addr = connection.address
                if (self.connections[addr!] != nil) {
                    self.printer.print("Removed: \(addr!)")
                    connection.close()
                    self.connections[addr!] = nil
                }
            }
        } else {
            let addr = connection.address
            if (self.connections[addr!] != nil) {
                connection.close()
                self.connections[addr!] = nil
            }
        }
        self.connectionListener!.onCloseConnection(connection.address!, reason)
    }
    
    
    public final class ServerDatagramHandler : ChannelInboundHandler {
        public typealias InboundIn = AddressedEnvelope<ByteBuffer>
        public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
        public var listener : Listener?
        
        public init (_ listener : Listener) {
            self.listener = listener
        }
        
        public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            //self.listener!.printer.print("Data \(data)")
            let packet = self.unwrapInboundIn(data)
            var content = packet.data
            if (content.readableBytes <= 0) {
                //self.listener!.printer.print("No data \(packet.remoteAddress)")
                // We have no use for empty packets.
                return;
            }
            let packetId = content.readInteger(as: UInt8.self)!
            content.moveReaderIndex(to: 0)
            let connection = listener!.connections[packet.remoteAddress]
            
            if (connection != nil) {
                connection!.recieve(&content)
                return
            }
            
            //self.listener!.printer.print("Unconnected: \(packetId)")
            
            // These packets don't require a session
            switch(packetId) {
            case PacketIdentifiers.UnconnectedPing:
                let decodePk = UnconnectedPing()
                decodePk.decode(&content)
                if !decodePk.valid(OfflinePacket.DEFAULT_MAGIC) {
                    return
                }
                
                let pk = UnconnectedPong()
                let motd = listener!.info!.toString()
                let packetLength = 35 + motd.count
                var buffer = context.channel.allocator.buffer(capacity: packetLength)
                pk.serverId = listener!.id
                pk.clientTime = decodePk.clientTime
                pk.info = motd
                pk.encode(&buffer)
                context.writeAndFlush(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: packet.remoteAddress, data: buffer)))
                break
            case PacketIdentifiers.OpenConnectionRequest1:
                let decodePk = OpenConnectionRequest1()
                decodePk.decode(&content)
                if !decodePk.valid(OfflinePacket.DEFAULT_MAGIC) {
                    return
                }
                
                var buffer : ByteBuffer? = nil
                
                self.listener!.printer.print("RakNet protocol: \(decodePk.protocolVersion)")
                
                if decodePk.protocolVersion != PROTOCOL {
                    buffer = context.channel.allocator.buffer(capacity: 26)
                    let pk = IncompatibleProtocolVersion()
                    pk.protocolVersion = Int32(PROTOCOL)
                    pk.serverId = listener!.id
                    pk.encode(&buffer!)
                } else {
                    let pk = OpenConnectionReply1()
                    buffer = context.channel.allocator.buffer(capacity: 28)
                    pk.serverId = listener!.id
                    pk.mtu = decodePk.mtu
                    
                    pk.encode(&buffer!)
                }
                context.writeAndFlush(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: packet.remoteAddress, data: buffer!)))
                break
            case PacketIdentifiers.OpenConnectionRequest2:
                let decodePk = OpenConnectionRequest2()
                decodePk.decode(&content)
                if !decodePk.valid(OfflinePacket.DEFAULT_MAGIC) {
                    return
                }
                
                let pk = OpenConnectionReply2()
                var buffer = context.channel.allocator.buffer(capacity: 31)
                pk.serverId = listener!.id
                pk.socketAddress = packet.remoteAddress
                
                let mtu = decodePk.mtu < 576 ? 576 : (decodePk.mtu > 1400 ? 1400 : decodePk.mtu)
                let adjustedMtu = mtu - 8 - (packet.remoteAddress.protocol == .inet6 ? 40 : 20)
                pk.mtu = adjustedMtu
                pk.encode(&buffer)
                context.writeAndFlush(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: packet.remoteAddress, data: buffer)))
                listener!.connections[packet.remoteAddress] = Connection(listener!, adjustedMtu, packet.remoteAddress)
                break
            default:
                //ignore
                break
            }
        }
        
//        public func channelReadComplete(context: ChannelHandlerContext) {
//            // As we are not really interested getting notified on success or failure we just pass nil as promise to
//            // reduce allocations.
//            context.flush()
//        }
        
        public func channelRegistered(context: ChannelHandlerContext) {
            //self.listener!.printer.print("Channel registered!")
        }
        
        public func channelActive(context: ChannelHandlerContext) {
            //self.listener!.printer.print("Channel active!")
        }
        
        public func channelInactive(context: ChannelHandlerContext) {
            //self.listener!.printer.print("Channel inactive!")
        }
        
        public func errorCaught(context: ChannelHandlerContext, error: Error) {
            //self.listener!.printer.print("An exception occurred in RakNet \(error.localizedDescription)")
            context.close(promise: nil)
        }
        
    }
}
