//
//  File.swift
//  
//
//  Created by Extollite on 11/11/2022.
//

import Foundation

public class TimeoutError: Error {
    
    public let message: String
    
    public init(_ message: String = "") {
        self.message = message
    }
}
