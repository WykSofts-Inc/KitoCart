//
//  KitoEmptyCartView.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// An empty cart that still feels alive: a cart floating in a soft halo with a few items
/// drifting around it, a friendly line and a button back to shopping. Reduce Motion holds it
/// still.
public struct KitoEmptyCartView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let message: String
    let actionTitle: String?
    let tint: Color?
    let action: (() -> Void)?

    @State private var floating = false

    public init(
        title: String = "Your cart is empty",
        message: String = "Browse the menu and add something you love.",
        actionTitle: String? = "Start shopping",
        tint: Color? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.tint = tint
        self.action = action
    }

    private var accent: Color { tint ?? theme.colors.primary }

    public var body: some View {
        VStack(spacing: 22) {
            illustration
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title).font(.title3.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.right")
                        .labelStyle(KitoTrailingIconLabelStyle())
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint == nil ? theme.colors.onPrimary : .white)
                        .padding(.horizontal, 22)
                        .frame(height: 48)
                        .background(accent, in: Capsule())
                }
                .buttonStyle(KitoStepperPressStyle())
            }
        }
        .foregroundStyle(theme.colors.onBackground)
        .padding(24)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { floating = true }
        }
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [accent.opacity(0.28), accent.opacity(0)], center: .center, startRadius: 10, endRadius: 110))
                .frame(width: 220, height: 220)
                .scaleEffect(floating ? 1.06 : 0.94)
            Circle()
                .strokeBorder(accent.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(floating ? 30 : 0))

            drifting("tag.fill", x: -78, y: -40, delay: 0)
            drifting("takeoutbag.and.cup.and.straw.fill", x: 80, y: -54, delay: 0.4)
            drifting("carrot.fill", x: 70, y: 58, delay: 0.8)
            drifting("cup.and.saucer.fill", x: -72, y: 60, delay: 1.2)

            Image(systemName: "cart")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 112, height: 112)
                .background(theme.colors.surface, in: Circle())
                .shadow(color: accent.opacity(0.3), radius: 20, y: 10)
                .offset(y: floating ? -6 : 6)
                .rotationEffect(.degrees(floating ? -4 : 4))
        }
        .frame(height: 220)
    }

    private func drifting(_ symbol: String, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(accent.opacity(0.8))
            .frame(width: 34, height: 34)
            .background(theme.colors.surface, in: Circle())
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .offset(x: x, y: y + (floating ? -8 : 8))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(delay), value: floating)
    }
}

struct KitoTrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.title
            configuration.icon
        }
    }
}
