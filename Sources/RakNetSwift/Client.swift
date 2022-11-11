//
//  ConnectionListener.swift
//  RakNetSwift
//
//  Created by Extollite on 13/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation
import NIO

let RAKNET_PING_INTERVAL = 1000

public class Client {
    struct StandardOutput : Printer {
        func print(_ msg: String) {
            Swift.print(msg)
        }
    }
    
    var id = Int64(arc4random()) &+ (Int64(arc4random()) << 32)
    
    var channel : Channel?
    
    var pings = [SocketAddress : PingEntry]()
    
    var shutdown = false
        
    var connectionListener : ConnectionListener?
    
    public var printer : Printer = StandardOutput()
    
    var updateTask : RepeatedTask?
        
    public init() {
        
    }
    
    public var allocator : ByteBufferAllocator {
        get {
            return self.channel!.allocator
        }
    }
    
    public func bind(_ host : String = "0.0.0.0", _ port : Int = 19132, _ group : EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)) -> EventLoopFuture<Void>? {
        var bootstrap = DatagramBootstrap(group: group).channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            
            // Set the handlers that are applied to the bound channel
            .channelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(ClientDatagramHandler(self), position: .last)
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
    
    public func close(){
        self.shutdown = true
        if channel != nil {
            channel!.close()
        }
    }
    
    public func sendBuffer(_ buffer : inout ByteBuffer, _ address : SocketAddress) {
        self.channel!.writeAndFlush(AddressedEnvelope(remoteAddress: address, data: buffer))
    }
    
    public func ping(_ address : SocketAddress) -> EventLoopFuture<ServerInfo> {
        if pings[address] != nil {
            return pings[address]!.promise.futureResult
        }
        
        let currentTime = Int(NSDate().timeIntervalSince1970 * 1000)
        let promise = channel!.eventLoop.next().makePromise(of: ServerInfo.self)
        
        pings[address] = PingEntry(promise, currentTime + 7000, currentTime)
        self.sendUnconnectedPing(address, currentTime)
        return promise.futureResult
    }
    
    func tick() {
        updateTask = channel!.eventLoop.next().scheduleRepeatedTask(initialDelay: TimeAmount.milliseconds(0), delay: TimeAmount.milliseconds(Int64(RAKNET_TICK_LENGTH * 1000)), {
            repeatedTask in
            if(!self.shutdown) {
                //self.printer.print("Tick")
                let currentTime = Int(NSDate().timeIntervalSince1970 * 1000)
                for (address, pingEntry) in self.pings {
                    if (currentTime >= pingEntry.timeout) {
                        pingEntry.promise.fail(TimeoutError("Ping timeout"))
                        self.pings[address] = nil
                    } else if ((currentTime - pingEntry.sendTime) >= RAKNET_PING_INTERVAL) {
                        pingEntry.sendTime = currentTime
                        self.sendUnconnectedPing(address, currentTime)
                    }
                }
            } else {
                repeatedTask.cancel()
            }
        })
    }
    
    func sendUnconnectedPing(_ address: SocketAddress, _ currentTime: Int) {
        let pk = UnconnectedPing()
        var buffer = self.channel!.allocator.buffer(capacity: 23)
        pk.clientId = id
        pk.clientTime = Int64(currentTime)
        pk.encode(&buffer)
        sendBuffer(&buffer, address)
    }
    
    public final class ClientDatagramHandler : ChannelInboundHandler {
        public typealias InboundIn = AddressedEnvelope<ByteBuffer>
        public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
        public var client : Client?
        
        public init (_ client : Client) {
            self.client = client
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
            
            // These packets don't require a session
            switch(packetId) {
            case PacketIdentifiers.UnconnectedPong:
                let decodePk = UnconnectedPong()
                decodePk.decode(&content)
                if !decodePk.valid(OfflinePacket.DEFAULT_MAGIC) {
                    return
                }
                
                let pingEntry = client!.pings[packet.remoteAddress]
                client!.pings[packet.remoteAddress] = nil
                pingEntry!.promise.succeed(ServerInfo.from(decodePk.info))
                
                break
            default:
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
