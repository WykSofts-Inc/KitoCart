//
//  KitoQuantityStepper.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How `KitoQuantityStepper` looks.
public enum KitoQuantityStepperStyle: String, Sendable, CaseIterable {
    /// − 2 + inside one capsule — cart rows.
    case capsule
    /// A single + that grows into − 1 + once tapped — menu and product cards.
    case expanding
    /// Separate circular buttons either side of the number — roomy product pages.
    case circles
    /// A tall pill with + on top — grocery tiles.
    case vertical

    public var label: String {
        switch self {
        case .capsule: return "Capsule"
        case .expanding: return "Expanding"
        case .circles: return "Circles"
        case .vertical: return "Vertical"
        }
    }
}

/// A quantity stepper whose number rolls as it changes, with a selection haptic on every step.
/// Pass `onRemove` to turn − into a trash button at the minimum.
///
/// ```swift
/// KitoQuantityStepper(value: $quantity, style: .expanding)
/// KitoQuantityStepper(value: $quantity, range: 1...20) { cart.remove(id: item.id) }
/// ```
public struct KitoQuantityStepper: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var value: Int
    let range: ClosedRange<Int>
    let style: KitoQuantityStepperStyle
    let tint: Color?
    let tintForeground: Color?
    let onRemove: (() -> Void)?

    /// - Parameters:
    ///   - tint: The filled parts; the theme's primary by default.
    ///   - tintForeground: Icons and text drawn on `tint` — pass `Color(.systemBackground)` with
    ///     a `.primary` tint for a black-in-light, white-in-dark capsule.
    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...99,
        style: KitoQuantityStepperStyle = .capsule,
        tint: Color? = nil,
        tintForeground: Color? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        _value = value
        self.range = range
        self.style = style
        self.tint = tint
        self.tintForeground = tintForeground
        self.onRemove = onRemove
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var onAccent: Color { tintForeground ?? (tint == nil ? theme.colors.onPrimary : .white) }
    private var showsTrash: Bool { onRemove != nil && value <= max(range.lowerBound, 1) }
    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72) }

    public var body: some View {
        content
            .sensoryFeedback(.selection, trigger: value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Quantity")
            .accessibilityValue("\(value)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(1)
                case .decrement: step(-1)
                @unknown default: break
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .capsule:
            HStack(spacing: 2) {
                minusButton(size: 32, filled: false)
                number(width: 26)
                plusButton(size: 32, filled: false)
            }
            .padding(3)
            .background(theme.colors.surfaceMuted, in: Capsule())
        case .circles:
            HStack(spacing: 14) {
                minusButton(size: 40, filled: false)
                    .background(Circle().strokeBorder(theme.colors.onBackground.opacity(0.15), lineWidth: 1.5))
                number(width: 30).font(.title3.weight(.bold))
                plusButton(size: 40, filled: true)
            }
        case .vertical:
            VStack(spacing: 2) {
                plusButton(size: 34, filled: false)
                number(width: 34)
                minusButton(size: 34, filled: false)
            }
            .padding(3)
            .background(theme.colors.surfaceMuted, in: Capsule())
        case .expanding:
            HStack(spacing: 2) {
                if value > range.lowerBound {
                    minusButton(size: 34, filled: false)
                        .foregroundStyle(onAccent)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                    number(width: 24)
                        .foregroundStyle(onAccent)
                        .transition(.opacity)
                }
                plusButton(size: 34, filled: false)
                    .foregroundStyle(onAccent)
            }
            .padding(3)
            .background(accent, in: Capsule())
            .animation(spring, value: value > range.lowerBound)
        }
    }

    private func number(width: CGFloat) -> some View {
        Text("\(value)")
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .frame(minWidth: width)
            .animation(spring, value: value)
    }

    private func minusButton(size: CGFloat, filled: Bool) -> some View {
        Button {
            if showsTrash, let onRemove {
                onRemove()
            } else {
                step(-1)
            }
        } label: {
            Image(systemName: showsTrash ? "trash" : "minus")
                .font(.system(size: size * 0.4, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
                .foregroundStyle(style == .expanding ? onAccent : (showsTrash ? theme.colors.danger : (filled ? onAccent : theme.colors.onBackground)))
                .background(filled ? accent : .clear, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(KitoStepperPressStyle())
        .disabled(!showsTrash && value <= range.lowerBound)
        .opacity(!showsTrash && value <= range.lowerBound ? 0.35 : 1)
        .accessibilityLabel(showsTrash ? "Remove" : "Decrease")
    }

    private func plusButton(size: CGFloat, filled: Bool) -> some View {
        Button { step(1) } label: {
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .bold))
                .frame(width: size, height: size)
                .foregroundStyle(filled ? onAccent : (style == .expanding ? onAccent : theme.colors.onBackground))
                .background(filled ? accent : .clear, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(KitoStepperPressStyle())
        .disabled(value >= range.upperBound)
        .opacity(value >= range.upperBound ? 0.35 : 1)
        .accessibilityLabel("Increase")
    }

    private func step(_ delta: Int) {
        let next = min(max(value + delta, range.lowerBound), range.upperBound)
        guard next != value else { return }
        withAnimation(spring) { value = next }
    }
}

/// A quick squash on press.
struct KitoStepperPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
