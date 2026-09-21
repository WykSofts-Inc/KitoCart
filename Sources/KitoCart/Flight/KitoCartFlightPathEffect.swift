//
//  KitoCartFlightPathEffect.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// A quadratic-bezier flight path as a `GeometryEffect` — the correct
/// SwiftUI technique for a smoothly-animated curved trajectory. A naive
/// `.position(computedPoint)` driven by a plain `@State` value does NOT
/// interpolate frame-by-frame; `GeometryEffect`'s `animatableData` does,
/// because SwiftUI's animation system drives it directly rather than diffing
/// two view snapshots.
struct KitoCartFlightPathEffect: GeometryEffect {
    var progress: CGFloat
    let start: CGPoint
    let end: CGPoint

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = progress
        // Control point arcs upward from the midpoint — reads as a "toss"
        // rather than a straight slide, which is what makes it feel alive.
        let controlPoint = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - 90)

        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * controlPoint.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * controlPoint.y + t * t * end.y

        return ProjectionTransform(CGAffineTransform(translationX: x - size.width / 2, y: y - size.height / 2))
    }
}
