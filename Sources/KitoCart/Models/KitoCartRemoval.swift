//
//  KitoCartRemoval.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A removed cart line and the position it came from, so an undo puts it back in place.
public struct KitoCartRemoval: Equatable, Sendable {
    public let item: KitoCartItem
    public let index: Int

    public init(item: KitoCartItem, index: Int) {
        self.item = item
        self.index = index
    }
}
