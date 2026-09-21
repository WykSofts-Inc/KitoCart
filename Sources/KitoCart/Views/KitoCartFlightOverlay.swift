//
//  KitoCartFlightOverlay.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

private struct KitoCartFlightItemView: View {
    let flight: KitoCartFlight
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1

    private static let duration: Double = 0.55

    var body: some View {
        Image(systemName: flight.symbol)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(flight.color)
            .scaleEffect(scale)
            .opacity(opacity)
            .modifier(KitoCartFlightPathEffect(
                progress: progress,
                start: CGPoint(x: flight.startFrame.midX, y: flight.startFrame.midY),
                end: CGPoint(x: flight.endFrame.midX, y: flight.endFrame.midY)
            ))
            .onAppear {
                withAnimation(.easeIn(duration: Self.duration)) {
                    progress = 1
                    scale = 0.35
                }
                withAnimation(.easeIn(duration: Self.duration * 0.4).delay(Self.duration * 0.6)) {
                    opacity = 0
                }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(Self.duration * 1_000_000_000))
                    onComplete()
                }
            }
    }
}

/// Renders every in-flight animation for a coordinator. Hosted automatically
/// by `.kitoCartFlightHost(_:)` — you don't construct this directly.
struct KitoCartFlightOverlay: View {
    @Bindable var coordinator: KitoCartFlightCoordinator

    var body: some View {
        ZStack {
            ForEach(coordinator.flights) { flight in
                KitoCartFlightItemView(flight: flight) {
                    coordinator.completeFlight(flight.id)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
