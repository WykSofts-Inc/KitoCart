//
//  KitoCartTests.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoCart

@MainActor
final class KitoCartTests: XCTestCase {
    func testAddNewItemAppends() {
        let cart = KitoCartViewModel()
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.totalQuantity, 1)
    }

    func testAddExistingItemMergesQuantityInsteadOfDuplicating() {
        let cart = KitoCartViewModel()
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5, quantity: 2))
        XCTAssertEqual(cart.items.count, 1, "same id must merge, not duplicate rows")
        XCTAssertEqual(cart.items[0].quantity, 3)
    }

    func testSubtotalSumsLineTotals() {
        let cart = KitoCartViewModel()
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5, quantity: 2))
        cart.add(KitoCartItem(id: "2", name: "Fries", unitPrice: 3, quantity: 1))
        XCTAssertEqual(cart.subtotal, 20)
    }

    func testSetQuantityToZeroRemovesItem() {
        let cart = KitoCartViewModel()
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
        cart.setQuantity(id: "1", quantity: 0)
        XCTAssertTrue(cart.isEmpty)
    }

    func testClearEmptiesCart() {
        let cart = KitoCartViewModel()
        cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
        cart.clear()
        XCTAssertTrue(cart.isEmpty)
        XCTAssertEqual(cart.subtotal, 0)
    }

    func testFlyWithUnregisteredFramesStillCallsOnArrive() {
        // No source/anchor registered — must not silently drop the intent,
        // since a real "add to cart" tap should never be lost just because
        // a view hasn't laid out yet.
        let coordinator = KitoCartFlightCoordinator()
        var arrived = false
        coordinator.fly(from: "missing") { arrived = true }
        XCTAssertTrue(arrived)
    }
}
