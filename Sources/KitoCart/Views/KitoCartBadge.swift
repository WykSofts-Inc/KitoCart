//
//  KitoCartBadge.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A cart icon with an animated count badge that bumps whenever `count`
/// changes — pair with `.kitoCartAnchor(_:)` so flying items know where to land.
public struct KitoCartBadge: View {
    @Environment(\.kitoTheme) private var theme
    let count: Int
    let systemImage: String

    @State private var isBumping = false

    public init(count: Int, systemImage: String = "cart.fill") {
        self.count = count
        self.systemImage = systemImage
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(theme.colors.onBackground)

            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(theme.colors.danger, in: Circle())
                    .scaleEffect(isBumping ? 1.35 : 1.0)
                    .offset(x: 10, y: -8)
            }
        }
        .onChange(of: count) { _, _ in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.35)) { isBumping = true }
            Task {
                try? await Task.sleep(nanoseconds: 180_000_000)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isBumping = false }
            }
        }
        .accessibilityLabel(count > 0 ? "Cart, \(count) items" : "Cart, empty")
    }
}
