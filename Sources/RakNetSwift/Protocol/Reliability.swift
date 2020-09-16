//
//  Reliability.swift
//  RakNetSwift
//
//  Created by Extollite on 10/09/2020.
//  Copyright © 2020 Extollite. All rights reserved.
//

import Foundation

public class Reliability {
    public static let UNRELIABLE = Reliability(0, false, false, false, false)
    public static let UNRELIABLE_SEQUENCED = Reliability(1, false, false, true, false)
    public static let RELIABLE = Reliability(2, true, false, false, false)
    public static let RELIABLE_ORDERED = Reliability(3, true, true, false, false)
    public static let RELIABLE_SEQUENCED = Reliability(4, true, false, true, false)
    public static let UNRELIABLE_WITH_ACK_RECEIPT = Reliability(5, false, false, false, true)
    public static let RELIABLE_WITH_ACK_RECEIPT = Reliability(6, true, false, false, true)
    public static let RELIABLE_ORDERED_WITH_ACK_RECEIPT = Reliability(7, true, true, false, true)

    private static let VALUES = [Reliability.UNRELIABLE, Reliability.UNRELIABLE_SEQUENCED, Reliability.RELIABLE, Reliability.RELIABLE_ORDERED, Reliability.RELIABLE_SEQUENCED, Reliability.UNRELIABLE_WITH_ACK_RECEIPT, Reliability.RELIABLE_WITH_ACK_RECEIPT, Reliability.RELIABLE_ORDERED_WITH_ACK_RECEIPT]

    let id : Int32
    let reliable : Bool
    let ordered : Bool
    let sequenced : Bool
    let withAckReceipt : Bool
    let size : Int32

    private init(_ id : Int32, _ reliable : Bool, _ ordered : Bool, _ sequenced : Bool, _ withAckReceipt : Bool) {
        self.id = id
        self.reliable = reliable
        self.ordered = ordered
        self.sequenced = sequenced
        self.withAckReceipt = withAckReceipt
        
        
        var size : Int32 = 0
        if (self.reliable) {
            size += 3
        }

        if (self.sequenced) {
            size += 3
        }

        if (self.ordered) {
            size += 4
        }
        self.size = size
        
    }

    public static func fromId(_ id: Int32) -> Reliability? {
        if (id < 0 || id > 7) {
            return nil
        }
        return VALUES[Int(id)]
    }
}

extension Reliability : Equatable {

    public static func == (lhs: Reliability, rhs: Reliability) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    public static func != (lhs: Reliability, rhs: Reliability) -> Bool {
        return lhs.id != rhs.id
    }
}
