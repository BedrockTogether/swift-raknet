//
//  File.swift
//
//
//  Created by Extollite on 13/09/2020.
//

import Foundation
import NIO

// Minecraft related protocol
let PROTOCOL = 10

// Raknet ticks
let RAKNET_TPS = 100
let RAKNET_TICK_LENGTH = 1.0 / Double(RAKNET_TPS)

public class Listener {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var id = Int64(arc4random()) &+ (Int64(arc4random()) << 32)
    
    var info : ServerInfo?
    
    var channel : Channel?
    
    public var connections = [SocketAddress : Connection]()
    
    var shutdown = false
    
    var bootstrap : DatagramBootstrap?
    
    var serverListener : ConnectionListener?
    
    public init () {
        
    }
    
    public func listen(_ serverInfo : ServerInfo, _ host : String = "0.0.0.0", _ port : Int = 19132) -> EventLoopFuture<Void>? {
        let handler = ServerDatagramHandler()
        handler.listener = self
        self.info = serverInfo
        bootstrap = DatagramBootstrap(group: group).channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            
            // Set the handlers that are applied to the bound channel
            .channelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(handler)
        }
        
        do {
            channel = try bootstrap!.bind(host: host, port: port).wait()
        } catch NIO.SocketAddressError.unknown(host: _, port: _) {
            return nil
        } catch {
            return nil
        }
        
        print("Server started and listening on \(channel!.localAddress!)")
        self.tick()

        return channel!.closeFuture
    }
    
    deinit {
        do {
            for con in self.connections {
                self.removeConnection(con.value, "shutdown")
            }
            channel!.close()
            try group.syncShutdownGracefully()
        } catch {
            
            // error
            return
        }
    }
    
    public func close(){
        do {
            for con in self.connections {
                self.removeConnection(con.value, "shutdown")
            }
            channel!.close()
            try group.syncShutdownGracefully()
        } catch {
            
            // error
            return
        }
    }
    
    func tick() {
        _ = channel!.eventLoop.next().scheduleRepeatedTask(initialDelay: TimeAmount.milliseconds(0), delay: TimeAmount.milliseconds(Int64(RAKNET_TICK_LENGTH * 1000)), {
            repeatedTask in
            if(!self.shutdown) {
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
        self.channel!.eventLoop.next().scheduleTask(in: TimeAmount.milliseconds(0), { () in
            let addr = connection.address
            if (self.connections[addr!] != nil) {
                connection.close()
                self.connections[addr!] = nil
            }
        })
        self.serverListener!.onCloseConnection(connection.address!, reason)
    }
    
    
    public class ServerDatagramHandler : ChannelInboundHandler {
        public typealias InboundIn = AddressedEnvelope<ByteBuffer>
        public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
        public var listener : Listener?
        var registred = false
        
        
        public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let packet = self.unwrapInboundIn(data)
            do {
                
                var content = packet.data
                if (content.readableBytes <= 0) {
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
        }
        
        public func channelRegistered(context: ChannelHandlerContext) {
            registred = true
        }
        
        
        public func errorCaught(context: ChannelHandlerContext, error: Error) {
            print("An exception occurred in RakNet", error)
        }
        
    }
}