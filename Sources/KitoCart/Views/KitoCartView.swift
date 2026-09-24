//
//  KitoCartView.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// One cart line: thumbnail, name, variant, price and a stepper; − turns into trash at one.
public struct KitoCartItemRow<Thumbnail: View>: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: KitoCartItem
    let currencyCode: String
    let stepperStyle: KitoQuantityStepperStyle
    @Binding var quantity: Int
    let onRemove: () -> Void
    let thumbnail: (KitoCartItem) -> Thumbnail

    public init(
        item: KitoCartItem,
        quantity: Binding<Int>,
        currencyCode: String = "KES",
        stepperStyle: KitoQuantityStepperStyle = .capsule,
        onRemove: @escaping () -> Void,
        @ViewBuilder thumbnail: @escaping (KitoCartItem) -> Thumbnail
    ) {
        self.item = item
        _quantity = quantity
        self.currencyCode = currencyCode
        self.stepperStyle = stepperStyle
        self.onRemove = onRemove
        self.thumbnail = thumbnail
    }

    public var body: some View {
        HStack(spacing: 14) {
            thumbnail(item)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.subheadline.weight(.bold)).lineLimit(1)
                if let subtitle = item.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(theme.colors.onBackground.opacity(0.55)).lineLimit(1)
                }
                Text(KitoCartMoney.string(item.lineTotal, currencyCode: currencyCode))
                    .font(.subheadline.weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .identity : .numericText(value: (item.lineTotal as NSDecimalNumber).doubleValue))
                    .animation(reduceMotion ? nil : .snappy, value: item.lineTotal)
                    .padding(.top, 2)
            }
            Spacer(minLength: 4)
            KitoQuantityStepper(value: $quantity, range: 1...99, style: stepperStyle, onRemove: onRemove)
        }
        .foregroundStyle(theme.colors.onBackground)
        .padding(12)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// A complete cart page: free-delivery progress, swipeable lines with undo, a promo code
/// field, the animated price breakdown and a checkout button — or the empty state.
///
/// ```swift
/// KitoCartView(cart: cart, rules: KitoCartPricingRules(deliveryFee: 150, freeDeliveryThreshold: 2_000),
///              promoValidator: validator, appliedPromo: $promo,
///              onCheckout: { pricing in pay(pricing.total, code: pricing.promo?.code) },
///              emptyTitle: "Your bag is empty", emptyMessage: "Pieces you add land here.") { item in
///     KitoRemoteImage(url: item.imageURL)
/// }
/// ```
///
/// The applied promo code travels with the pricing handed to `onCheckout` (`pricing.promo`).
/// Pass `appliedPromo` to read or set it from outside, or `onPromoChange` to hear about it.
/// For a completely different empty state, use `.emptyState { MyEmptyView() }`.
public struct KitoCartView<Thumbnail: View>: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var cart: KitoCartViewModel
    let rules: KitoCartPricingRules
    let promoValidator: KitoPromoValidator?
    let currencyCode: String
    let checkoutTitle: String
    let onCheckout: (KitoCartPricing) -> Void
    let onBrowse: (() -> Void)?
    let appliedPromo: Binding<KitoPromoCode?>?
    let onPromoChange: ((KitoPromoCode?) -> Void)?
    let emptyTitle: String
    let emptyMessage: String
    let emptyActionTitle: String?
    let thumbnail: (KitoCartItem) -> Thumbnail
    private var customEmpty: AnyView?

    @State private var localPromo: KitoPromoCode?

    public init(
        cart: KitoCartViewModel,
        rules: KitoCartPricingRules = KitoCartPricingRules(),
        promoValidator: KitoPromoValidator? = nil,
        currencyCode: String = "KES",
        checkoutTitle: String = "Checkout",
        onCheckout: @escaping (KitoCartPricing) -> Void,
        onBrowse: (() -> Void)? = nil,
        appliedPromo: Binding<KitoPromoCode?>? = nil,
        onPromoChange: ((KitoPromoCode?) -> Void)? = nil,
        emptyTitle: String = "Your cart is empty",
        emptyMessage: String = "Add something you love and it'll show up here.",
        emptyActionTitle: String? = "Start shopping",
        @ViewBuilder thumbnail: @escaping (KitoCartItem) -> Thumbnail
    ) {
        self.cart = cart
        self.rules = rules
        self.promoValidator = promoValidator
        self.currencyCode = currencyCode
        self.checkoutTitle = checkoutTitle
        self.onCheckout = onCheckout
        self.onBrowse = onBrowse
        self.appliedPromo = appliedPromo
        self.onPromoChange = onPromoChange
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptyActionTitle = emptyActionTitle
        self.thumbnail = thumbnail
    }

    /// Replaces the built-in empty state with your own view.
    public func emptyState<Empty: View>(@ViewBuilder _ content: () -> Empty) -> KitoCartView {
        var copy = self
        copy.customEmpty = AnyView(content())
        return copy
    }

    /// The applied promo: the caller's binding when there is one, otherwise the view's own state.
    private var promoBinding: Binding<KitoPromoCode?> {
        let external = appliedPromo
        let local = $localPromo
        let onChange = onPromoChange
        return Binding(
            get: { external?.wrappedValue ?? local.wrappedValue },
            set: { newValue in
                if let external { external.wrappedValue = newValue } else { local.wrappedValue = newValue }
                onChange?(newValue)
            }
        )
    }

    private var promo: KitoPromoCode? { appliedPromo?.wrappedValue ?? localPromo }

    private var pricing: KitoCartPricing { rules.pricing(subtotal: cart.subtotal, promo: promo) }
    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82) }

    public var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            if cart.isEmpty {
                emptyView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                content.transition(.opacity)
            }
        }
        .animation(spring, value: cart.isEmpty)
        .kitoCartUndoBar(cart, bottomInset: cart.isEmpty ? 0 : 72)
    }

    @ViewBuilder private var emptyView: some View {
        if let customEmpty {
            customEmpty
        } else {
            KitoEmptyCartView(title: emptyTitle, message: emptyMessage, actionTitle: emptyActionTitle, action: onBrowse)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                if rules.freeDeliveryThreshold != nil {
                    KitoFreeDeliveryProgress(pricing: pricing, currencyCode: currencyCode)
                        .padding(16)
                        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                ForEach(cart.items) { item in
                    KitoCartItemRow(
                        item: item,
                        quantity: Binding(get: { cart.quantity(of: item.id) }, set: { cart.setQuantity(id: item.id, quantity: $0) }),
                        currencyCode: currencyCode,
                        onRemove: { withAnimation(spring) { cart.remove(id: item.id) } },
                        thumbnail: thumbnail
                    )
                    .kitoSwipeToDelete(cornerRadius: 22) { withAnimation(spring) { cart.remove(id: item.id) } }
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                }
                if let promoValidator {
                    KitoPromoCodeField(applied: promoBinding, validator: promoValidator, subtotal: cart.subtotal, currencyCode: currencyCode)
                        .padding(.top, 6)
                }
                KitoPriceBreakdown(pricing: pricing, currencyCode: currencyCode)
                    .padding(18)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(16)
            .padding(.bottom, 8)
            .animation(spring, value: cart.items.map(\.id))
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { checkoutBar }
    }

    private var checkoutBar: some View {
        Button { onCheckout(pricing) } label: {
            HStack {
                Text(checkoutTitle).font(.headline)
                Spacer()
                Text(KitoCartMoney.string(pricing.total, currencyCode: currencyCode))
                    .font(.headline.weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .identity : .numericText(value: (pricing.total as NSDecimalNumber).doubleValue))
            }
            .foregroundStyle(theme.colors.onPrimary)
            .padding(.horizontal, 22)
            .frame(height: 56)
            .background(theme.colors.primary, in: Capsule())
        }
        .buttonStyle(KitoStepperPressStyle())
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
        .animation(spring, value: pricing.total)
    }
}
