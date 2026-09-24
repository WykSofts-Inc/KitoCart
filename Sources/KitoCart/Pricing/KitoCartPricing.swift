//
//  KitoCartPricing.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A store's pricing rules — delivery fee, free-delivery threshold, service fee, tax. Turn a
/// subtotal (and any promo) into a full `KitoCartPricing` with `pricing(subtotal:promo:)`.
public struct KitoCartPricingRules: Equatable, Sendable {
    public var deliveryFee: Decimal
    /// Subtotal at which delivery becomes free; `nil` for never.
    public var freeDeliveryThreshold: Decimal?
    /// Fraction of the subtotal, e.g. 0.02 for 2%.
    public var serviceFeeRate: Decimal
    /// Fraction of the discounted subtotal, e.g. 0.16 for 16% VAT. Zero when prices include tax.
    public var taxRate: Decimal

    public init(deliveryFee: Decimal = 0, freeDeliveryThreshold: Decimal? = nil, serviceFeeRate: Decimal = 0, taxRate: Decimal = 0) {
        self.deliveryFee = deliveryFee
        self.freeDeliveryThreshold = freeDeliveryThreshold
        self.serviceFeeRate = serviceFeeRate
        self.taxRate = taxRate
    }

    public func pricing(subtotal: Decimal, promo: KitoPromoCode? = nil) -> KitoCartPricing {
        KitoCartPricing(subtotal: subtotal, rules: self, promo: promo)
    }
}

/// Every line of a cart's price breakdown, worked out once. Amounts are rounded to cents.
public struct KitoCartPricing: Equatable, Sendable {
    public let subtotal: Decimal
    public let rules: KitoCartPricingRules
    public let promo: KitoPromoCode?

    public init(subtotal: Decimal, rules: KitoCartPricingRules, promo: KitoPromoCode? = nil) {
        self.subtotal = max(subtotal, 0)
        self.rules = rules
        self.promo = promo
    }

    public var discount: Decimal {
        guard let promo, isPromoEligible else { return 0 }
        switch promo.kind {
        case .percent(let percent, let cap):
            let raw = Self.rounded(subtotal * percent / 100)
            return min(cap.map { min(raw, $0) } ?? raw, subtotal)
        case .fixed(let amount):
            return min(amount, subtotal)
        case .freeDelivery:
            return 0
        }
    }

    /// Whether the applied promo's minimum is met (a code can stop applying when items are removed).
    public var isPromoEligible: Bool {
        guard let promo else { return false }
        if let minimum = promo.minimumSubtotal { return subtotal >= minimum }
        return true
    }

    public var qualifiesForFreeDelivery: Bool {
        if promo?.kind == .freeDelivery, isPromoEligible { return true }
        guard let threshold = rules.freeDeliveryThreshold else { return false }
        return subtotal >= threshold
    }

    /// The delivery fee actually charged.
    public var deliveryFee: Decimal {
        subtotal == 0 || qualifiesForFreeDelivery ? 0 : rules.deliveryFee
    }

    /// The fee that was waived, for a struck-through "KES 150 Free" line.
    public var waivedDeliveryFee: Decimal {
        subtotal > 0 && qualifiesForFreeDelivery ? rules.deliveryFee : 0
    }

    public var serviceFee: Decimal { Self.rounded(subtotal * rules.serviceFeeRate) }

    public var tax: Decimal { Self.rounded((subtotal - discount) * rules.taxRate) }

    public var total: Decimal { subtotal - discount + deliveryFee + serviceFee + tax }

    /// How much more to spend for free delivery; zero once reached or when there's no threshold.
    public var amountToFreeDelivery: Decimal {
        guard let threshold = rules.freeDeliveryThreshold, !qualifiesForFreeDelivery else { return 0 }
        return max(threshold - subtotal, 0)
    }

    /// 0...1 towards the free-delivery threshold.
    public var freeDeliveryProgress: Double {
        if qualifiesForFreeDelivery { return 1 }
        guard let threshold = rules.freeDeliveryThreshold, threshold > 0 else { return 0 }
        return min(max((subtotal / threshold as NSDecimalNumber).doubleValue, 0), 1)
    }

    static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }
}

/// Money text for the cart views: "KES 1,250", "KES 1,250.50", "$42". Fixed grouping so a
/// cart reads the same on every device.
public enum KitoCartMoney {
    public static func string(_ amount: Decimal, currencyCode: String = "KES") -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.decimalSeparator = "."
        var whole = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &whole, 0, .plain)
        let digits = rounded == amount ? 0 : 2
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        let number = formatter.string(from: abs(amount) as NSDecimalNumber) ?? "\(amount)"
        let sign = amount < 0 ? "-" : ""
        switch currencyCode.uppercased() {
        case "USD": return sign + "$" + number
        case "EUR": return sign + "€" + number
        case "GBP": return sign + "£" + number
        default: return sign + currencyCode.uppercased() + " " + number
        }
    }
}
