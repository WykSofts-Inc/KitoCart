//
//  KitoPriceBreakdown.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Subtotal, discount, delivery, fees and total — every amount rolls to its new value, the
/// discount line slides in when a code applies, and waived delivery shows struck through.
///
/// ```swift
/// KitoPriceBreakdown(pricing: rules.pricing(subtotal: cart.subtotal, promo: promo))
/// ```
public struct KitoPriceBreakdown: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pricing: KitoCartPricing
    let currencyCode: String
    let totalLabel: String

    public init(pricing: KitoCartPricing, currencyCode: String = "KES", totalLabel: String = "Total") {
        self.pricing = pricing
        self.currencyCode = currencyCode
        self.totalLabel = totalLabel
    }

    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82) }

    public var body: some View {
        VStack(spacing: 12) {
            row("Subtotal", pricing.subtotal)
            if pricing.discount > 0, let promo = pricing.promo {
                row("Discount · \(promo.code)", -pricing.discount, color: theme.colors.success, symbol: "tag.fill")
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            deliveryRow
            if pricing.serviceFee > 0 {
                row("Service fee", pricing.serviceFee)
            }
            if pricing.tax > 0 {
                row("VAT", pricing.tax)
            }
            Divider().overlay(theme.colors.onBackground.opacity(0.08))
            HStack(alignment: .firstTextBaseline) {
                Text(totalLabel).font(.headline)
                Spacer()
                money(pricing.total)
                    .font(.title2.weight(.heavy))
            }
            .accessibilityElement(children: .combine)
        }
        .foregroundStyle(theme.colors.onBackground)
        .animation(spring, value: pricing)
    }

    private var deliveryRow: some View {
        HStack {
            Label("Delivery", systemImage: "scooter")
                .labelStyle(KitoLeadingIconLabelStyle())
                .foregroundStyle(theme.colors.onBackground.opacity(0.65))
            Spacer()
            if pricing.waivedDeliveryFee > 0 {
                Text(KitoCartMoney.string(pricing.waivedDeliveryFee, currencyCode: currencyCode))
                    .strikethrough()
                    .foregroundStyle(theme.colors.onBackground.opacity(0.4))
                Text("Free")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.colors.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                money(pricing.deliveryFee)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func row(_ title: String, _ amount: Decimal, color: Color? = nil, symbol: String? = nil) -> some View {
        HStack {
            if let symbol {
                Label(title, systemImage: symbol).labelStyle(KitoLeadingIconLabelStyle())
                    .foregroundStyle(color ?? theme.colors.onBackground.opacity(0.65))
            } else {
                Text(title).foregroundStyle(color ?? theme.colors.onBackground.opacity(0.65))
            }
            Spacer()
            money(amount).foregroundStyle(color ?? theme.colors.onBackground)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func money(_ amount: Decimal) -> some View {
        Text(KitoCartMoney.string(amount, currencyCode: currencyCode))
            .fontWeight(.semibold)
            .monospacedDigit()
            .contentTransition(reduceMotion ? .identity : .numericText(value: (amount as NSDecimalNumber).doubleValue))
    }
}

struct KitoLeadingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.caption.weight(.semibold))
            configuration.title
        }
    }
}

/// "Add KES 350 more for free delivery" with a scooter riding along the bar — it turns into a
/// celebratory check once the threshold is reached.
public struct KitoFreeDeliveryProgress: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pricing: KitoCartPricing
    let currencyCode: String
    let tint: Color?

    public init(pricing: KitoCartPricing, currencyCode: String = "KES", tint: Color? = nil) {
        self.pricing = pricing
        self.currencyCode = currencyCode
        self.tint = tint
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var reached: Bool { pricing.qualifiesForFreeDelivery }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: reached ? "checkmark.seal.fill" : "shippingbox.fill")
                    .foregroundStyle(reached ? theme.colors.success : accent)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: reached)
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.opacity)
            }
            GeometryReader { proxy in
                let progress = CGFloat(pricing.freeDeliveryProgress)
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.colors.onBackground.opacity(0.08)).frame(height: 10)
                    Capsule()
                        .fill(LinearGradient(colors: reached ? [theme.colors.success, theme.colors.success.opacity(0.7)] : [accent.opacity(0.6), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, proxy.size.width * progress), height: 10)
                    Image(systemName: "scooter")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(reached ? theme.colors.success : accent, in: Circle())
                        .overlay(Circle().stroke(theme.colors.background, lineWidth: 2))
                        .offset(x: min(max(proxy.size.width * progress - 13, 0), proxy.size.width - 26))
                }
                .frame(height: 26)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 26)
        }
        .foregroundStyle(theme.colors.onBackground)
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.78), value: pricing.freeDeliveryProgress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityValue("\(Int(pricing.freeDeliveryProgress * 100)) percent")
    }

    private var message: String {
        reached
            ? "You've unlocked free delivery"
            : "Add \(KitoCartMoney.string(pricing.amountToFreeDelivery, currencyCode: currencyCode)) more for free delivery"
    }
}
