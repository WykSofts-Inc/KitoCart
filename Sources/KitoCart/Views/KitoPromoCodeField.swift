//
//  KitoPromoCodeField.swift
//  KitoCart
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A promo code entry that checks the code, shakes and explains when it's wrong, and turns
/// into a ticket chip (with a remove button) once it applies.
///
/// ```swift
/// @State private var promo: KitoPromoCode?
///
/// KitoPromoCodeField(applied: $promo, validator: validator, subtotal: cart.subtotal)
/// ```
public struct KitoPromoCodeField: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var applied: KitoPromoCode?
    let currencyCode: String
    let validate: (String) async -> Result<KitoPromoCode, KitoPromoError>

    @State private var text = ""
    @State private var isChecking = false
    @State private var error: KitoPromoError?
    @State private var shakes = 0
    @FocusState private var focused: Bool

    /// Checks codes with your own logic — typically a server call.
    public init(
        applied: Binding<KitoPromoCode?>,
        currencyCode: String = "KES",
        validate: @escaping (String) async -> Result<KitoPromoCode, KitoPromoError>
    ) {
        _applied = applied
        self.currencyCode = currencyCode
        self.validate = validate
    }

    /// Checks codes against a `KitoPromoValidator`, with a short pause so it feels checked.
    public init(applied: Binding<KitoPromoCode?>, validator: KitoPromoValidator, subtotal: Decimal, currencyCode: String = "KES") {
        self.init(applied: applied, currencyCode: currencyCode) { code in
            try? await Task.sleep(nanoseconds: 550_000_000)
            return validator.validate(code, subtotal: subtotal)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let applied {
                appliedChip(applied)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                entry
                    .transition(.opacity)
            }
            if let error, applied == nil {
                Label(error.message(currencyCode: currencyCode), systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.colors.danger)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.78), value: applied)
        .animation(.easeOut(duration: 0.2), value: error)
    }

    private var entry: some View {
        HStack(spacing: 10) {
            Image(systemName: "ticket")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.colors.onBackground.opacity(0.5))
            TextField("Promo code", text: $text)
                .font(.body.weight(.semibold).monospaced())
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(apply)
                .onChange(of: text) { _, _ in if error != nil { error = nil } }
            Button(action: apply) {
                ZStack {
                    Text("Apply").opacity(isChecking ? 0 : 1)
                    if isChecking { ProgressView().tint(theme.colors.onPrimary) }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.colors.onPrimary)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(theme.colors.primary.opacity(text.isEmpty ? 0.4 : 1), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty || isChecking)
            .accessibilityLabel(isChecking ? "Checking code" : "Apply code")
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(height: 48)
        .background(theme.colors.surfaceMuted, in: Capsule())
        .overlay(Capsule().strokeBorder(error == nil ? Color.clear : theme.colors.danger, lineWidth: 1.5))
        .modifier(KitoShakeEffect(shakes: CGFloat(shakes)))
        .sensoryFeedback(.error, trigger: shakes)
    }

    private func appliedChip(_ code: KitoPromoCode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundStyle(theme.colors.success)
                .symbolEffect(.bounce, value: code.code)
            VStack(alignment: .leading, spacing: 1) {
                Text(code.code).font(.subheadline.weight(.heavy).monospaced())
                Text(code.title).font(.caption).foregroundStyle(theme.colors.onBackground.opacity(0.6))
            }
            Spacer()
            Button {
                applied = nil
                text = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(theme.colors.onBackground.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove code \(code.code)")
        }
        .foregroundStyle(theme.colors.onBackground)
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(theme.colors.success.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.colors.success.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
        .sensoryFeedback(.success, trigger: code.code)
    }

    private func apply() {
        guard !text.isEmpty, !isChecking else { return }
        focused = false
        isChecking = true
        let input = text
        Task { @MainActor in
            let result = await validate(input)
            isChecking = false
            switch result {
            case .success(let code):
                error = nil
                applied = code
            case .failure(let failure):
                error = failure
                if !reduceMotion { withAnimation(.linear(duration: 0.4)) { shakes += 1 } } else { shakes += 1 }
            }
        }
    }
}

/// A horizontal shake, one full wobble per unit of `shakes`.
struct KitoShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}
