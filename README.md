# swift-raknet


Simple RakNet server built with usage of [SwiftNIO](https://github.com/apple/swift-nio).

## Usage
Add to Package.swift:
```swift
.package(url: "https://github.com/Extollite/swift-raknet", from: ...)
```

Example listener [swift-raknet/Sources/Test/main.swift](https://github.com/Extollite/swift-raknet/blob/master/Sources/Test/main.swift)

## Todo
- [x] Server-Client handshake
- [x] Packets reassembly
- [x] Working ipv6 
- [ ] Use fast data structure instead of swift standard library
- [ ] Stability tweaks
- [ ] Reliability tweaks
- [ ] Better documentation 

## Thanks
Huge thanks to creators of listed below repository creators for valuable source of knowledge.
- [CloudburstMC/Network](https://github.com/CloudburstMC/Network)
- [yesdog/netty-raknet](https://github.com/yesdog/netty-raknet)
- [HerryYT/JSRakNet](https://github.com/HerryYT/JSRakNet)
