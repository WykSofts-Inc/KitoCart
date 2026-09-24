//
//  KitoSwipeToDelete.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

public extension View {
    /// Swipe left to reveal a Delete button; swipe far enough and the row slides away and
    /// `onDelete` runs. Works in a `ScrollView`/`VStack`, not only in a `List`. VoiceOver gets a
    /// Delete action instead of the gesture.
    func kitoSwipeToDelete(cornerRadius: CGFloat = 18, label: String = "Remove", onDelete: @escaping () -> Void) -> some View {
        modifier(KitoSwipeToDeleteModifier(cornerRadius: cornerRadius, label: label, onDelete: onDelete))
    }
}

private struct KitoSwipeToDeleteModifier: ViewModifier {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cornerRadius: CGFloat
    let label: String
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var restingOffset: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var isDeleting = false

    private let revealWidth: CGFloat = 88

    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82) }
    private var pastThreshold: Bool { width > 0 && -offset > width * 0.5 }

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            deleteBackground
            content
                .offset(x: offset)
                .simultaneousGesture(drag)
        }
        .background(GeometryReader { proxy in Color.clear.onAppear { width = proxy.size.width } })
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .sensoryFeedback(.impact(weight: .medium), trigger: pastThreshold) { _, new in new }
        .accessibilityAction(named: label) { delete() }
    }

    private var deleteBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.colors.danger)
            .overlay(alignment: .trailing) {
                Button(action: delete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .symbolEffect(.bounce, value: pastThreshold)
                        Text(label).font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: max(revealWidth, -offset))
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
            .opacity(offset < 0 ? 1 : 0)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let proposed = restingOffset + value.translation.width
                offset = proposed > 0 ? proposed * 0.15 : proposed
            }
            .onEnded { value in
                let predicted = restingOffset + value.predictedEndTranslation.width
                if pastThreshold || (width > 0 && -predicted > width * 0.8) {
                    delete()
                } else if offset < -revealWidth * 0.5 {
                    withAnimation(spring) { offset = -revealWidth }
                    restingOffset = -revealWidth
                } else {
                    withAnimation(spring) { offset = 0 }
                    restingOffset = 0
                }
            }
    }

    private func delete() {
        guard !isDeleting else { return }
        isDeleting = true
        withAnimation(reduceMotion ? nil : .easeIn(duration: 0.22)) { offset = -max(width, 400) }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.2)) {
            onDelete()
            offset = 0
            restingOffset = 0
            isDeleting = false
        }
    }
}

/// A snackbar with an Undo button and a ring that empties as it times out — pair with
/// `KitoCartViewModel.undoRemoval()`.
public struct KitoUndoBar: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String
    let duration: TimeInterval
    let onUndo: () -> Void
    let onTimeout: () -> Void

    @State private var remaining: CGFloat = 1

    public init(_ message: String, duration: TimeInterval = 4, onUndo: @escaping () -> Void, onTimeout: @escaping () -> Void = {}) {
        self.message = message
        self.duration = duration
        self.onUndo = onUndo
        self.onTimeout = onTimeout
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.white.opacity(0.2), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "trash").font(.system(size: 11, weight: .bold))
            }
            .frame(width: 26, height: 26)

            Text(message)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.colors.warning)
                .buttonStyle(.plain)
                .accessibilityHint("Puts the item back in your cart")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.12), in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        .task(id: message) {
            remaining = 1
            withAnimation(.linear(duration: duration)) { remaining = 0 }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled { onTimeout() }
        }
        .accessibilityElement(children: .combine)
    }
}

public extension View {
    /// Shows a `KitoUndoBar` for the cart's last removal, from the bottom, until it's undone or
    /// times out.
    /// - Parameter bottomInset: Extra space below the bar, e.g. to sit above a checkout button.
    func kitoCartUndoBar(_ cart: KitoCartViewModel, duration: TimeInterval = 4, bottomInset: CGFloat = 0) -> some View {
        modifier(KitoCartUndoBarModifier(cart: cart, duration: duration, bottomInset: bottomInset))
    }
}

private struct KitoCartUndoBarModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cart: KitoCartViewModel
    let duration: TimeInterval
    let bottomInset: CGFloat

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let removal = cart.recentlyRemoved {
                KitoUndoBar("Removed \(removal.item.name)", duration: duration) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { _ = cart.undoRemoval() }
                } onTimeout: {
                    withAnimation(.easeOut(duration: 0.25)) { cart.clearRecentlyRemoved() }
                }
                .id(removal.item.id + "\(removal.index)")
                .padding(.horizontal, 16)
                .padding(.bottom, 12 + bottomInset)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: cart.recentlyRemoved)
    }
}
