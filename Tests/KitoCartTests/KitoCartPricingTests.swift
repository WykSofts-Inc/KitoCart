//
//  KitoCartPricingTests.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoCart

@MainActor
final class KitoCartPricingTests: XCTestCase {
    private let rules = KitoCartPricingRules(deliveryFee: 150, freeDeliveryThreshold: 2_000, serviceFeeRate: 0.02)

    // MARK: Pricing

    func testTotalAddsDeliveryAndServiceFee() {
        let pricing = rules.pricing(subtotal: 1_000)
        XCTAssertEqual(pricing.deliveryFee, 150)
        XCTAssertEqual(pricing.serviceFee, 20)
        XCTAssertEqual(pricing.total, 1_170)
    }

    func testFreeDeliveryOnceThresholdReached() {
        let pricing = rules.pricing(subtotal: 2_500)
        XCTAssertTrue(pricing.qualifiesForFreeDelivery)
        XCTAssertEqual(pricing.deliveryFee, 0)
        XCTAssertEqual(pricing.waivedDeliveryFee, 150)
        XCTAssertEqual(pricing.amountToFreeDelivery, 0)
        XCTAssertEqual(pricing.freeDeliveryProgress, 1)
    }

    func testAmountAndProgressToFreeDelivery() {
        let pricing = rules.pricing(subtotal: 1_500)
        XCTAssertEqual(pricing.amountToFreeDelivery, 500)
        XCTAssertEqual(pricing.freeDeliveryProgress, 0.75, accuracy: 0.0001)
    }

    func testEmptyCartChargesNothing() {
        XCTAssertEqual(rules.pricing(subtotal: 0).total, 0)
    }

    func testPercentPromoWithCap() {
        let promo = KitoPromoCode(code: "karibu10", kind: .percent(10, cap: 300))
        XCTAssertEqual(promo.code, "KARIBU10")
        XCTAssertEqual(rules.pricing(subtotal: 1_000, promo: promo).discount, 100)
        XCTAssertEqual(rules.pricing(subtotal: 5_000, promo: promo).discount, 300)
    }

    func testFixedPromoNeverExceedsSubtotal() {
        let promo = KitoPromoCode(code: "SAVE500", kind: .fixed(500))
        XCTAssertEqual(rules.pricing(subtotal: 300, promo: promo).discount, 300)
    }

    func testFreeDeliveryPromo() {
        let promo = KitoPromoCode(code: "FREESHIP", kind: .freeDelivery)
        let pricing = rules.pricing(subtotal: 800, promo: promo)
        XCTAssertEqual(pricing.deliveryFee, 0)
        XCTAssertEqual(pricing.discount, 0)
    }

    func testPromoStopsApplyingBelowMinimum() {
        let promo = KitoPromoCode(code: "BIG", kind: .fixed(200), minimumSubtotal: 1_500)
        XCTAssertEqual(rules.pricing(subtotal: 1_000, promo: promo).discount, 0)
        XCTAssertEqual(rules.pricing(subtotal: 1_600, promo: promo).discount, 200)
    }

    func testTaxOnDiscountedSubtotal() {
        let taxed = KitoCartPricingRules(taxRate: 0.16)
        let promo = KitoPromoCode(code: "X", kind: .fixed(100))
        XCTAssertEqual(taxed.pricing(subtotal: 1_100, promo: promo).tax, 160)
    }

    // MARK: Promo validation

    func testValidatorOutcomes() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let validator = KitoPromoValidator(codes: [
            KitoPromoCode(code: "KARIBU", kind: .percent(10)),
            KitoPromoCode(code: "OLD", kind: .fixed(50), expiresAt: now.addingTimeInterval(-60)),
            KitoPromoCode(code: "BIG", kind: .fixed(200), minimumSubtotal: 1_500),
        ])
        XCTAssertEqual(validator.validate("  karibu ", subtotal: 100, now: now), .success(validator.codes[0]))
        XCTAssertEqual(validator.validate("", subtotal: 100, now: now), .failure(.empty))
        XCTAssertEqual(validator.validate("NOPE", subtotal: 100, now: now), .failure(.notFound))
        XCTAssertEqual(validator.validate("old", subtotal: 100, now: now), .failure(.expired))
        XCTAssertEqual(validator.validate("big", subtotal: 100, now: now), .failure(.minimumNotMet(1_500)))
    }

    func testPromoErrorMessageMentionsMinimum() {
        XCTAssertEqual(KitoPromoError.minimumNotMet(1_500).message(), "Spend KES 1,500 to use this code.")
    }

    // MARK: Money

    func testCartMoney() {
        XCTAssertEqual(KitoCartMoney.string(1_250), "KES 1,250")
        XCTAssertEqual(KitoCartMoney.string(Decimal(string: "1250.5")!), "KES 1,250.50")
        XCTAssertEqual(KitoCartMoney.string(42, currencyCode: "USD"), "$42")
        XCTAssertEqual(KitoCartMoney.string(-100), "-KES 100")
    }

    // MARK: Undo and steppers

    func testRemoveThenUndoRestoresPosition() {
        let cart = KitoCartViewModel(items: [
            KitoCartItem(id: "a", name: "Chapati", unitPrice: 30),
            KitoCartItem(id: "b", name: "Pilau", unitPrice: 450),
            KitoCartItem(id: "c", name: "Chai", unitPrice: 80),
        ])
        cart.remove(id: "b")
        XCTAssertEqual(cart.recentlyRemoved?.item.id, "b")
        XCTAssertEqual(cart.recentlyRemoved?.index, 1)
        XCTAssertTrue(cart.undoRemoval())
        XCTAssertEqual(cart.items.map(\.id), ["a", "b", "c"])
        XCTAssertNil(cart.recentlyRemoved)
        XCTAssertFalse(cart.undoRemoval())
    }

    func testDecrementToZeroRemovesUndoably() {
        let cart = KitoCartViewModel(items: [KitoCartItem(id: "a", name: "Mandazi", unitPrice: 20)])
        cart.decrement(id: "a")
        XCTAssertTrue(cart.isEmpty)
        XCTAssertEqual(cart.recentlyRemoved?.item.id, "a")
    }

    func testIncrementAndQuantity() {
        let cart = KitoCartViewModel(items: [KitoCartItem(id: "a", name: "Samosa", unitPrice: 50)])
        cart.increment(id: "a", by: 2)
        XCTAssertEqual(cart.quantity(of: "a"), 3)
        XCTAssertEqual(cart.quantity(of: "missing"), 0)
    }

    func testFlightStylesHaveSensibleDurations() {
        for style in KitoCartFlightStyle.allCases {
            XCTAssertGreaterThan(style.duration, 0)
        }
        XCTAssertGreaterThan(KitoCartFlightStyle.lob.lift, KitoCartFlightStyle.arc.lift)
    }
}
