//
//  KitoCartItem.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// One line in the cart. `id` should be the product/SKU id — stable across
/// quantity changes, since `KitoCartViewModel.add` merges by `id` rather
/// than appending a duplicate row.
public struct KitoCartItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var unitPrice: Decimal
    public var quantity: Int
    public var imageURL: URL?
    /// A second line under the name — size, variant, seller ("Large · Oat milk").
    public var subtitle: String?

    public init(id: String, name: String, unitPrice: Decimal, quantity: Int = 1, imageURL: URL? = nil, subtitle: String? = nil) {
        self.id = id
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.imageURL = imageURL
        self.subtitle = subtitle
    }

    public var lineTotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}
