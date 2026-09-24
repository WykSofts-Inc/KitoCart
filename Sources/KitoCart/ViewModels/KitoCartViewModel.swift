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
/// its quantity rather than creating a duplicate row. Removals are remembered
/// once so they can be undone. Pricing lives in `KitoCartPricingRules` /
/// `KitoCartPricing`, and promo codes in `KitoPromoValidator`, so this type
/// stays about line items only.
@Observable
public final class KitoCartViewModel: KitoViewModel {
    public private(set) var items: [KitoCartItem] = []
    /// The last line removed, and where it was — what `undoRemoval()` puts back.
    public private(set) var recentlyRemoved: KitoCartRemoval?

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
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        recentlyRemoved = KitoCartRemoval(item: items[index], index: index)
        items.remove(at: index)
    }

    /// Puts the last removed line back where it was. Returns `false` if there's nothing to undo.
    @discardableResult
    public func undoRemoval() -> Bool {
        guard let removal = recentlyRemoved else { return false }
        recentlyRemoved = nil
        if let existing = items.firstIndex(where: { $0.id == removal.item.id }) {
            items[existing].quantity += removal.item.quantity
        } else {
            items.insert(removal.item, at: min(removal.index, items.count))
        }
        return true
    }

    /// Forgets the last removal, e.g. once its undo banner has gone.
    public func clearRecentlyRemoved() {
        recentlyRemoved = nil
    }

    public func quantity(of id: String) -> Int {
        items.first { $0.id == id }?.quantity ?? 0
    }

    public func increment(id: String, by amount: Int = 1) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].quantity += amount
    }

    /// Lowers the quantity by one, removing the line (undoably) when it reaches zero.
    public func decrement(id: String) {
        setQuantity(id: id, quantity: quantity(of: id) - 1)
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
