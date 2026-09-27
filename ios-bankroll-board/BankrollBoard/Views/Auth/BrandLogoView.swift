//
//  BrandLogoView.swift
//  BankrollBoard
//

import SwiftUI
import UIKit

/// Bankroll Board logo. Uses the bundled `BrandLogo` image when present,
/// otherwise draws the forest-and-gold monogram mark.
struct BrandLogoView: View {
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let image = UIImage(named: "BrandLogo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size * 1.22)
                    .shadow(color: AuthPalette.forest.opacity(0.22), radius: 18, y: 10)
            } else {
                monogram
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Bankroll Board")
    }

    private var monogram: some View {
        let radius = size * 0.28
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AuthPalette.forestLight, AuthPalette.forest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius * 0.78, style: .continuous)
                    .strokeBorder(AuthPalette.gold.opacity(0.4), lineWidth: 1)
                    .padding(size * 0.07)
            }
            .overlay {
                Text("B")
                    .font(.system(size: size * 0.56, weight: .regular, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BBTheme.goldBright, AuthPalette.gold, BBTheme.goldDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -size * 0.015)
            }
            .frame(width: size, height: size)
            .shadow(color: AuthPalette.forest.opacity(0.22), radius: 18, y: 10)
    }
}

#Preview {
    BrandLogoView(size: 88)
        .padding(40)
        .background(AuthPalette.paper)
}
