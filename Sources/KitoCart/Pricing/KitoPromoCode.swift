//
//  KitoPromoCode.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A promo code and what it does.
public struct KitoPromoCode: Identifiable, Equatable, Hashable, Sendable {
    public enum Kind: Equatable, Hashable, Sendable {
        /// Percent off the subtotal (10 = 10%), optionally capped.
        case percent(Decimal, cap: Decimal? = nil)
        /// A fixed amount off, never more than the subtotal.
        case fixed(Decimal)
        /// Delivery is free.
        case freeDelivery
    }

    public var id: String { code }
    /// Stored uppercased; matching ignores case and surrounding spaces.
    public let code: String
    public var kind: Kind
    /// The subtotal the cart must reach before the code applies.
    public var minimumSubtotal: Decimal?
    public var expiresAt: Date?
    /// A short line for the applied chip: "10% off", "KES 200 off", "Free delivery".
    public var title: String

    public init(code: String, kind: Kind, minimumSubtotal: Decimal? = nil, expiresAt: Date? = nil, title: String? = nil) {
        self.code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.kind = kind
        self.minimumSubtotal = minimumSubtotal
        self.expiresAt = expiresAt
        self.title = title ?? Self.defaultTitle(for: kind)
    }

    private static func defaultTitle(for kind: Kind) -> String {
        switch kind {
        case .percent(let percent, _): return "\(NSDecimalNumber(decimal: percent).stringValue)% off"
        case .fixed(let amount): return "\(NSDecimalNumber(decimal: amount).stringValue) off"
        case .freeDelivery: return "Free delivery"
        }
    }
}

/// Why a promo code didn't apply.
public enum KitoPromoError: Error, Equatable, Sendable {
    case empty
    case notFound
    case expired
    case minimumNotMet(Decimal)

    /// Copy for the field's error line.
    public func message(currencyCode: String = "KES") -> String {
        switch self {
        case .empty: return "Enter a promo code."
        case .notFound: return "That code isn't valid."
        case .expired: return "That code has expired."
        case .minimumNotMet(let minimum): return "Spend \(KitoCartMoney.string(minimum, currencyCode: currencyCode)) to use this code."
        }
    }
}

/// Checks codes against a known list — for demos, offline catalogues, or as the client-side
/// check before your server confirms.
public struct KitoPromoValidator: Sendable {
    public var codes: [KitoPromoCode]

    public init(codes: [KitoPromoCode]) {
        self.codes = codes
    }

    public func validate(_ input: String, subtotal: Decimal, now: Date = Date()) -> Result<KitoPromoCode, KitoPromoError> {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return .failure(.empty) }
        guard let code = codes.first(where: { $0.code == normalized }) else { return .failure(.notFound) }
        if let expiry = code.expiresAt, expiry <= now { return .failure(.expired) }
        if let minimum = code.minimumSubtotal, subtotal < minimum { return .failure(.minimumNotMet(minimum)) }
        return .success(code)
    }
}
