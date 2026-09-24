//
//  KitoCartFlight.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// The path and motion of an item flying to the cart.
public enum KitoCartFlightStyle: String, Sendable, CaseIterable {
    /// A gentle toss — the original.
    case arc
    /// A high lob that hangs for a moment before dropping in.
    case lob
    /// Straight to the badge, shrinking fast.
    case dart
    /// An arc with the icon spinning end over end.
    case spin

    public var label: String {
        switch self {
        case .arc: return "Arc"
        case .lob: return "Lob"
        case .dart: return "Dart"
        case .spin: return "Spin"
        }
    }

    /// How far above the higher end the path's control point sits.
    var lift: CGFloat {
        switch self {
        case .arc, .spin: return 90
        case .lob: return 240
        case .dart: return 0
        }
    }

    var duration: Double {
        switch self {
        case .arc, .spin: return 0.55
        case .lob: return 0.8
        case .dart: return 0.38
        }
    }
}

struct KitoCartFlight: Identifiable {
    let id: UUID
    let startFrame: CGRect
    let endFrame: CGRect
    let symbol: String
    let color: Color
    var style: KitoCartFlightStyle = .arc
    let onArrive: (() -> Void)?
}
