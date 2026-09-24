# Adding the Fly-to-Cart Animation

Animate an icon from the tapped view to your cart badge, adding the item when it lands.

## Overview

The animation needs three pieces: a host for the flying-icon overlay, an anchor
on the cart badge, and a source on each view that can trigger a flight. The
coordinator does not care what triggers it; it only needs the tapped view's
frame registered as a source.

### Wire the host once near the root

Create a ``KitoCartViewModel`` and a ``KitoCartFlightCoordinator``, host the
overlay with `kitoCartFlightHost(_:)`, and share both through the environment.

```swift
@State private var cart = KitoCartViewModel()
@State private var cartFlight = KitoCartFlightCoordinator()

var body: some View {
    NavigationStack {
        ProductListScreen()
    }
    .kitoCartFlightHost(cartFlight)
    .environment(cart)
    .environment(cartFlight)
}
```

### Mark the destination

The cart badge is where every flight ends. Register it with
`kitoCartAnchor(_:)`.

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink(destination: CartScreen()) {
            KitoCartBadge(count: cart.totalQuantity)
        }
        .kitoCartAnchor(cartFlight)
    }
}
```

### Register sources and fly

Register each tappable view with `kitoCartFlightSource(id:in:)`, then call
``KitoCartFlightCoordinator/fly(from:symbol:color:style:onArrive:)`` where you
would otherwise add the item directly.

```swift
Button {
    cartFlight.fly(from: "combo-1", symbol: "bag.fill") {
        cart.add(KitoCartItem(id: "combo-1", name: "Family Combo", unitPrice: 24.99))
    }
} label: {
    Text("Add")
}
.kitoCartFlightSource(id: "combo-1", in: cartFlight)
```

The `onArrive` closure runs when the icon lands, not on tap, so the badge
update and the icon's arrival read as one continuous motion. Because each view
registers its own source identifier, cards anywhere on screen fly correctly to
the same badge.

### Choose a flight style

Pass a ``KitoCartFlightStyle`` to change the path: `.arc` (the default), `.lob`,
`.dart`, or `.spin`.

```swift
cartFlight.fly(from: product.id, symbol: "bag.fill", style: .lob) {
    cart.add(item)
}
```
