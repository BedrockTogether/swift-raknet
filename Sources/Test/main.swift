//
//  File.swift
//  
//
//  Created by Extollite on 14/09/2020.
//

import Foundation
import RakNetNIO

do {
    let listener = Listener()
    let info = ServerInfo("RakNetSwift Test", "RakNetSwift", 409, "1.16.40", 0, 5, "Creative", 0)
    try listener.listen(info)!.wait()
} catch {
    //ignore
}
