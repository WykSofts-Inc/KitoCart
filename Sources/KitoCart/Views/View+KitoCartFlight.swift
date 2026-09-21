//
//  View+KitoCartFlight.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

public extension View {
    /// Registers this view's on-screen frame as a flight *source* under
    /// `id` — attach to your "Add to Cart" button (or its containing row/card).
    ///
    /// ```swift
    /// KitoButton("Add to cart") {
    ///     cartFlight.fly(from: product.id, symbol: "takeoutbag.and.cup.and.straw.fill") {
    ///         cart.add(KitoCartItem(id: product.id, name: product.name, unitPrice: product.price))
    ///         KitoHaptics.success()
    ///     }
    /// }
    /// .kitoCartFlightSource(id: product.id, in: cartFlight)
    /// ```
    func kitoCartFlightSource(id: String, in coordinator: KitoCartFlightCoordinator) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
            }
        )
        .onPreferenceChange(FramePreferenceKey.self) { frame in
            coordinator.registerSource(id: id, frame: frame)
        }
    }

    /// Registers this view's on-screen frame as the flight *destination* —
    /// attach to your cart icon/badge, typically in a toolbar.
    func kitoCartAnchor(_ coordinator: KitoCartFlightCoordinator) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
            }
        )
        .onPreferenceChange(FramePreferenceKey.self) { frame in
            coordinator.registerCartAnchor(frame: frame)
        }
    }

    /// Hosts the flying-item animation overlay for this coordinator. Call
    /// once, near the root of the screen (or the app) — every
    /// `coordinator.fly(from:)` call anywhere in that subtree renders here.
    func kitoCartFlightHost(_ coordinator: KitoCartFlightCoordinator) -> some View {
        overlay(KitoCartFlightOverlay(coordinator: coordinator))
    }
}
