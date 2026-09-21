// swift-tools-version: 5.9
//
//  Package.swift
//  KitoCart
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoCart",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoCart", targets: ["KitoCart"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoCart", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoCartTests", dependencies: ["KitoCart"]),
    ]
)
