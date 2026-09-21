//
//  KitoCartFlightCoordinator.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation
import KitoCore

/// Coordinates "fly an icon from a tapped button to the cart badge."
/// Register the cart icon's position once with `.kitoCartAnchor(_:)`, register
/// each "Add to Cart" button's position with `.kitoCartFlightSource(id:in:)`,
/// then call `fly(from:)` — typically from your existing button's action
/// closure, right next to `cart.add(item)`. One coordinator serves an entire
/// screen; share it via `@State` + `.environment(_:)` the same way you'd
/// share a `KitoToastCenter`.
@Observable
public final class KitoCartFlightCoordinator: KitoViewModel {
    fileprivate var cartAnchorFrame: CGRect = .zero
    fileprivate var sourceFrames: [String: CGRect] = [:]
    private(set) var flights: [KitoCartFlight] = []

    public init() {}

    public func registerCartAnchor(frame: CGRect) {
        cartAnchorFrame = frame
    }

    public func registerSource(id: String, frame: CGRect) {
        sourceFrames[id] = frame
    }

    /// Starts one flight from the registered source `id` to the registered
    /// cart anchor. No-ops silently (never crashes) if either frame hasn't
    /// been registered yet — e.g. the cart icon hasn't appeared, or you
    /// passed an `id` that was never attached to a view.
    ///
    /// - Parameters:
    ///   - symbol: SF Symbol shown as the flying icon — usually your
    ///     product's category icon, or just `"cart.fill"`.
    ///   - onArrive: Called when the flight completes — the natural place to
    ///     bump `KitoCartViewModel.add(item)`, so the cart count updates in
    ///     sync with the animation landing rather than instantly on tap.
    public func fly(from sourceID: String, symbol: String = "cart.fill", color: Color = .accentColor, onArrive: (() -> Void)? = nil) {
        guard let start = sourceFrames[sourceID], cartAnchorFrame != .zero else {
            // Frame not ready yet — still honor the intent so cart state
            // doesn't silently drop an add just because the animation can't play.
            onArrive?()
            return
        }
        let flight = KitoCartFlight(id: UUID(), startFrame: start, endFrame: cartAnchorFrame, symbol: symbol, color: color, onArrive: onArrive)
        flights.append(flight)
    }

    func completeFlight(_ id: UUID) {
        guard let index = flights.firstIndex(where: { $0.id == id }) else { return }
        let flight = flights.remove(at: index)
        flight.onArrive?()
    }
}
