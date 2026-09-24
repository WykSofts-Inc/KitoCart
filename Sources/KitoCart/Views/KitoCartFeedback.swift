//
//  KitoCartFeedback.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A floating "3 items · KES 1,250 — View cart" bar that springs up when the cart fills and
/// bounces every time something is added.
public struct KitoMiniCartBar: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let count: Int
    let total: Decimal
    let currencyCode: String
    let title: String
    let tint: Color?
    let tintForeground: Color?
    let action: () -> Void

    @State private var bounce = 0

    public init(
        count: Int,
        total: Decimal,
        currencyCode: String = "KES",
        title: String = "View cart",
        tint: Color? = nil,
        tintForeground: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.count = count
        self.total = total
        self.currencyCode = currencyCode
        self.title = title
        self.tint = tint
        self.tintForeground = tintForeground
        self.action = action
    }

    private var ink: Color { tintForeground ?? (tint == nil ? theme.colors.onPrimary : .white) }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(ink.opacity(0.16), in: Circle())
                    Text("\(count)")
                        .font(.system(size: 11, weight: .heavy))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(count)))
                        .foregroundStyle(tint ?? theme.colors.primary)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(ink, in: Circle())
                        .offset(x: 4, y: -4)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline.weight(.bold))
                    Text("\(count) \(count == 1 ? "item" : "items")")
                        .font(.caption)
                        .opacity(0.75)
                        .contentTransition(.numericText(value: Double(count)))
                }
                Spacer()
                Text(KitoCartMoney.string(total, currencyCode: currencyCode))
                    .font(.headline.weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: (total as NSDecimalNumber).doubleValue))
                Image(systemName: "chevron.forward").font(.caption.weight(.bold)).opacity(0.7)
            }
            .foregroundStyle(ink)
            .padding(.leading, 8)
            .padding(.trailing, 18)
            .padding(.vertical, 8)
            .background(tint ?? theme.colors.primary, in: Capsule())
            .shadow(color: (tint ?? theme.colors.primary).opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(KitoStepperPressStyle())
        .keyframeAnimator(initialValue: CGFloat(1), trigger: bounce) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(1.06, duration: 0.14)
                SpringKeyframe(0.98, duration: 0.12)
                SpringKeyframe(1, duration: 0.2)
            }
        }
        .onChange(of: count) { old, new in
            guard new > old, !reduceMotion else { return }
            bounce += 1
        }
        .animation(reduceMotion ? nil : .snappy, value: count)
        .accessibilityLabel("\(title), \(count) items, \(KitoCartMoney.string(total, currencyCode: currencyCode))")
    }
}

/// How the "Added to cart" confirmation appears.
public enum KitoAddedToCartStyle: String, Sendable, CaseIterable {
    /// A small pill that drops from the top, like a Dynamic Island alert.
    case pill
    /// A full-width banner that slides up from the bottom with a View cart button.
    case banner
    /// A card that pops in the centre with the item's details.
    case card

    public var label: String {
        switch self {
        case .pill: return "Pill"
        case .banner: return "Banner"
        case .card: return "Card"
        }
    }
}

/// The "Added to cart" confirmation itself — use `.kitoAddedToCartToast(item:)` to present it.
public struct KitoAddedToCartToast: View {
    @Environment(\.kitoTheme) private var theme
    let item: KitoCartItem
    let style: KitoAddedToCartStyle
    let currencyCode: String
    let onViewCart: (() -> Void)?

    public init(item: KitoCartItem, style: KitoAddedToCartStyle = .pill, currencyCode: String = "KES", onViewCart: (() -> Void)? = nil) {
        self.item = item
        self.style = style
        self.currencyCode = currencyCode
        self.onViewCart = onViewCart
    }

    public var body: some View {
        Group {
            switch style {
            case .pill: pill
            case .banner: banner
            case .card: card
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Added \(item.name) to cart")
    }

    private var check: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(theme.colors.success, in: Circle())
            .symbolEffect(.bounce, value: item.id)
    }

    private var pill: some View {
        HStack(spacing: 10) {
            check
            Text("Added").font(.subheadline.weight(.bold))
            Text(item.name).font(.subheadline).lineLimit(1).opacity(0.75)
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(Color.black, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }

    private var banner: some View {
        HStack(spacing: 12) {
            check
            VStack(alignment: .leading, spacing: 1) {
                Text("Added to cart").font(.subheadline.weight(.bold))
                Text("\(item.quantity) × \(item.name)").font(.caption).opacity(0.7).lineLimit(1)
            }
            Spacer()
            if let onViewCart {
                Button("View cart", action: onViewCart)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.colors.onPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(theme.colors.primary, in: Capsule())
                    .buttonStyle(.plain)
            }
        }
        .foregroundStyle(theme.colors.onSurface)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.colors.onBackground.opacity(0.08)))
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
    }

    private var card: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(theme.colors.success.opacity(0.15)).frame(width: 74, height: 74)
                Image(systemName: "bag.fill.badge.plus")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(theme.colors.success)
                    .symbolEffect(.bounce, value: item.id)
            }
            Text("Added to cart").font(.headline)
            VStack(spacing: 2) {
                Text(item.name).font(.subheadline.weight(.semibold))
                if let subtitle = item.subtitle { Text(subtitle).font(.caption).opacity(0.6) }
                Text(KitoCartMoney.string(item.lineTotal, currencyCode: currencyCode))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .padding(.top, 4)
            }
            if let onViewCart {
                Button("View cart", action: onViewCart)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(theme.colors.primary, in: Capsule())
                    .buttonStyle(.plain)
            }
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.colors.onSurface)
        .padding(22)
        .frame(width: 250)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 28, y: 12)
    }
}

public extension View {
    /// Shows a `KitoAddedToCartToast` whenever `item` is set, then clears it after `duration`.
    ///
    /// ```swift
    /// @State private var justAdded: KitoCartItem?
    /// …
    /// .kitoAddedToCartToast(item: $justAdded, style: .banner) { showCart = true }
    /// ```
    func kitoAddedToCartToast(
        item: Binding<KitoCartItem?>,
        style: KitoAddedToCartStyle = .pill,
        currencyCode: String = "KES",
        duration: TimeInterval = 2.2,
        onViewCart: (() -> Void)? = nil
    ) -> some View {
        modifier(KitoAddedToCartModifier(item: item, style: style, currencyCode: currencyCode, duration: duration, onViewCart: onViewCart))
    }
}

private struct KitoAddedToCartModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var item: KitoCartItem?
    let style: KitoAddedToCartStyle
    let currencyCode: String
    let duration: TimeInterval
    let onViewCart: (() -> Void)?

    private var alignment: Alignment {
        switch style {
        case .pill: return .top
        case .banner: return .bottom
        case .card: return .center
        }
    }

    private var transition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        switch style {
        case .pill: return .move(edge: .top).combined(with: .scale(scale: 0.6, anchor: .top)).combined(with: .opacity)
        case .banner: return .move(edge: .bottom).combined(with: .opacity)
        case .card: return .scale(scale: 0.7).combined(with: .opacity)
        }
    }

    private var viewCartAction: (() -> Void)? {
        guard let onViewCart else { return nil }
        return {
            item = nil
            onViewCart()
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if let item {
                    KitoAddedToCartToast(item: item, style: style, currencyCode: currencyCode, onViewCart: viewCartAction)
                    .padding(.horizontal, style == .banner ? 16 : 0)
                    .padding(.vertical, style == .card ? 0 : 12)
                    .transition(transition)
                    .onTapGesture { self.item = nil }
                    .zIndex(1)
                }
            }
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.74), value: item)
            .sensoryFeedback(.success, trigger: item?.id) { _, new in new != nil }
            .task(id: item.map { "\($0.id)-\($0.quantity)" }) {
                guard item != nil else { return }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                if !Task.isCancelled { item = nil }
            }
    }
}
