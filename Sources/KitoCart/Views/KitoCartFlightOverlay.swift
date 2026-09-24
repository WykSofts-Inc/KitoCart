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
    var origin: CGPoint = .zero
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        let duration = reduceMotion ? 0.25 : flight.style.duration
        Image(systemName: flight.symbol)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(flight.color)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .modifier(KitoCartFlightPathEffect(
                progress: progress,
                start: CGPoint(x: flight.startFrame.midX - origin.x, y: flight.startFrame.midY - origin.y),
                end: CGPoint(x: flight.endFrame.midX - origin.x, y: flight.endFrame.midY - origin.y),
                lift: reduceMotion ? 0 : flight.style.lift
            ))
            .onAppear {
                let curve: Animation = flight.style == .lob ? .timingCurve(0.3, 0.0, 0.6, 1, duration: duration) : .easeIn(duration: duration)
                withAnimation(curve) {
                    progress = 1
                    scale = flight.style == .dart ? 0.2 : 0.35
                    if flight.style == .spin && !reduceMotion { rotation = 540 }
                }
                withAnimation(.easeIn(duration: duration * 0.4).delay(duration * 0.6)) {
                    opacity = 0
                }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
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
        // Source and anchor frames are registered in global coordinates; convert them into
        // this overlay's own space so the flight lines up wherever the host sits (a full
        // screen, a sheet, a card in a scroll view), and pin items to the top-leading corner
        // so the path effect's translation starts from a known origin.
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            ZStack(alignment: .topLeading) {
                ForEach(coordinator.flights) { flight in
                    KitoCartFlightItemView(flight: flight, origin: origin) {
                        coordinator.completeFlight(flight.id)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .allowsHitTesting(false)
    }
}
