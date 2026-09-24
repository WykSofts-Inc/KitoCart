# ``KitoCart``

Cart state management with ready-made cart components and a curved fly-to-cart animation.

## Overview

KitoCart separates cart state from presentation. ``KitoCartViewModel`` holds the
line items, quantities, subtotal, and the most recent removal so it can be
undone. Pricing lives in ``KitoCartPricingRules`` and ``KitoCartPricing``, and
promo codes in ``KitoPromoValidator``, so the view model stays about line items
only. It is fully usable on its own if you only need cart state.

```swift
@State private var cart = KitoCartViewModel()

cart.add(KitoCartItem(id: "1", name: "Burger", unitPrice: 8.5))
```

For a complete cart page, ``KitoCartView`` combines free-delivery progress,
swipe-to-delete with undo, promo codes, an animated price breakdown, checkout,
and an empty state. Each piece is also available on its own, including
``KitoQuantityStepper``, ``KitoPromoCodeField``, ``KitoPriceBreakdown``, and
``KitoMiniCartBar``.

``KitoCartFlightCoordinator`` adds an animation in which an icon arcs from the
tapped view to your cart badge, and the item is added when it lands. Every
animation respects Reduce Motion, and amounts are formatted with fixed grouping
through ``KitoCartMoney`` so a cart reads the same on every device.

## Topics

### Essentials

- <doc:FlyToCart>
- ``KitoCartViewModel``
- ``KitoCartItem``
- ``KitoCartRemoval``

### Cart Page

- ``KitoCartView``
- ``KitoCartItemRow``
- ``KitoEmptyCartView``

### Components

- ``KitoCartBadge``
- ``KitoQuantityStepper``
- ``KitoQuantityStepperStyle``
- ``KitoMiniCartBar``
- ``KitoAddedToCartToast``
- ``KitoAddedToCartStyle``
- ``KitoUndoBar``

### Pricing and Promo Codes

- ``KitoCartPricingRules``
- ``KitoCartPricing``
- ``KitoPriceBreakdown``
- ``KitoFreeDeliveryProgress``
- ``KitoPromoCode``
- ``KitoPromoValidator``
- ``KitoPromoError``
- ``KitoPromoCodeField``
- ``KitoCartMoney``

### Fly-to-Cart Animation

- ``KitoCartFlightCoordinator``
- ``KitoCartFlightStyle``
