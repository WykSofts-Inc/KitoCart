//
//  KitoCartFlight.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

struct KitoCartFlight: Identifiable {
    let id: UUID
    let startFrame: CGRect
    let endFrame: CGRect
    let symbol: String
    let color: Color
    let onArrive: (() -> Void)?
}
