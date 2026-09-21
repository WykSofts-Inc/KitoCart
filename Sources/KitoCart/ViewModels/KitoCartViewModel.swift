//
//  KitoCartViewModel.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import Observation
import KitoCore

/// Owns the cart's line items. Adding an item already in the cart increments
/// its quantity rather than creating a duplicate row — that's the one
/// business rule this type enforces; everything else (pricing rules, taxes,
/// promo codes) is your checkout ViewModel's job, not this one's.
@Observable
public final class KitoCartViewModel: KitoViewModel {
    public private(set) var items: [KitoCartItem] = []

    public init(items: [KitoCartItem] = []) {
        self.items = items
    }

    public var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public var subtotal: Decimal {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public func add(_ item: KitoCartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity += item.quantity
        } else {
            items.append(item)
        }
    }

    public func remove(id: String) {
        items.removeAll { $0.id == id }
    }

    public func setQuantity(id: String, quantity: Int) {
        guard quantity > 0 else { remove(id: id); return }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].quantity = quantity
    }

    public func clear() {
        items.removeAll()
    }
}
