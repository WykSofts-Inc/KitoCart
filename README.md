# KitoCart

Cart state management (MVVM) plus a proper "fly to cart" animation — an
icon arcs from wherever the user tapped to your cart badge, using
`GeometryEffect` for a genuinely smooth curved path, not a naive position
tween.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoCart.git", from: "1.0.0"),
```

## Setup — three pieces, wired once near your root

```swift
@State private var cart = KitoCartViewModel()
@State private var cartFlight = KitoCartFlightCoordinator()

var body: some View {
    NavigationStack {
        ProductListScreen()
    }
    .kitoCartFlightHost(cartFlight)   // hosts the flying-icon overlay
    .environment(cart)
    .environment(cartFlight)
}
```

## Samples

### 1. The cart badge, in a toolbar — this is the flight's destination

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

### 2. "Add to Cart" using your existing `KitoButtons` button

This is the point — the flight system doesn't care what triggers it, it just
needs the tapped view's frame registered as a source, and a call to `fly(from:)`
wherever you'd otherwise call `cart.add(item)` directly:

```swift
import KitoButtons   // your existing button kit
import KitoCart

struct ProductCard: View {
    let product: Product
    @Environment(KitoCartViewModel.self) private var cart
    @Environment(KitoCartFlightCoordinator.self) private var cartFlight

    var body: some View {
        VStack {
            // ... product image, name, price ...

            KitoButton("Add to Cart", style: .primary) {
                cartFlight.fly(from: product.id, symbol: "cart.fill") {
                    cart.add(KitoCartItem(
                        id: product.id,
                        name: product.name,
                        unitPrice: product.price,
                        imageURL: product.imageURL
                    ))
                    KitoHaptics.success()   // from KitoHaptics — the landing "thunk"
                }
            }
            .kitoCartFlightSource(id: product.id, in: cartFlight)
        }
    }
}
```

The animation plays for ~0.55s; `cart.add(item)` (and the haptic) fires when
it *lands*, not on tap — so the badge bump and the icon's arrival read as
one continuous motion instead of two disconnected events.

### 3. A product grid — every card independently flies to the same badge

```swift
ScrollView {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]) {
        ForEach(products) { product in
            ProductCard(product: product)   // from sample 2 above
        }
    }
}
```

Because each card registers its *own* source `id` (the product id), tapping
different cards animates from wherever that specific card is on screen —
not a fixed point — so a card near the top and one near the bottom both fly
correctly to the toolbar badge.

### 4. Cart screen — quantity stepper, remove, subtotal

```swift
struct CartScreen: View {
    @Environment(KitoCartViewModel.self) private var cart

    var body: some View {
        if cart.isEmpty {
            KitoEmptyStateView.noData(title: "Your cart is empty")   // from KitoEmptyStates
        } else {
            List {
                ForEach(cart.items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Stepper(
                            "\(item.quantity)",
                            value: Binding(
                                get: { item.quantity },
                                set: { cart.setQuantity(id: item.id, quantity: $0) }
                            ),
                            in: 0...20
                        )
                        Text(item.lineTotal, format: .currency(code: "KES"))
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { cart.remove(id: cart.items[index].id) }
                }

                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(cart.subtotal, format: .currency(code: "KES"))
                        .font(.headline)
                }
            }
        }
    }
}
```

### 5. Without KitoButtons — works with any tappable view

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

### 6. Skip the animation, keep the cart logic

Nothing requires the flight coordinator — `KitoCartViewModel` is fully
usable on its own if you only want cart state:

```swift
@State private var cart = KitoCartViewModel()
cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
```

## How the animation actually works

`KitoCartFlightPathEffect` is a `GeometryEffect` (not a plain `.position()`
tween) — its `animatableData` is driven directly by SwiftUI's animation
system frame-by-frame, which is what makes the curved arc interpolate
smoothly instead of jumping. See the doc comment on that type if you're
customizing the curve.

## License

MIT
