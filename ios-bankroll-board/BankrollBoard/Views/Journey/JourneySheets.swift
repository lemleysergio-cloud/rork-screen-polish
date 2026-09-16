//
//  JourneySheets.swift
//  BankrollBoard
//

import SwiftUI

/// State chooser. Mirrors the web dialog copy exactly.
struct JourneyRegionPicker: View {
    let regions: [JourneyRegion]
    let selectedID: String
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose your state")
                .font(BBTheme.headline(28))
                .foregroundStyle(BBTheme.ink)

            Text("Browse bonuses where you can play. This choice does not verify your location. One signup bonus per casino, across all states.")
                .font(.system(size: 14))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            VStack(spacing: 8) {
                ForEach(regions) { region in
                    let isSelected = region.id == selectedID
                    Button(action: {
                        Haptics.selection()
                        onSelect(region.id)
                    }) {
                        HStack {
                            Text(region.name)
                                .font(.system(size: 16))
                                .foregroundStyle(BBTheme.ink)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(BBTheme.gold)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? BBTheme.gold.opacity(0.09) : .clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isSelected ? BBTheme.gold : BBTheme.hairline.opacity(0.6),
                                            lineWidth: isSelected ? 1.6 : 1
                                        )
                                }
                        }
                    }
                    .buttonStyle(BBPressStyle())
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }

                Button(action: {
                    Haptics.tap()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16))
                        .foregroundStyle(BBTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                        }
                }
                .buttonStyle(BBPressStyle())
            }
            .padding(.top, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
        .presentationBackground(BBTheme.canvasDeep)
    }
}

/// Offer detail sheet opened from the orbit or the trail.
struct JourneyOfferSheet: View {
    let offer: JourneyOffer
    let onOpenOfficial: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    JourneyBrandTile(mark: offer.mark, side: 56)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(offer.rankLabel.uppercased()) · \(offer.state.trailLabel.uppercased())")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(0.8)
                            .foregroundStyle(BBTheme.gold)

                        Text(offer.name)
                            .font(BBTheme.headline(26))
                            .foregroundStyle(BBTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(offer.headline)
                    .font(.system(size: 15))
                    .foregroundStyle(BBTheme.inkMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                VStack(spacing: 0) {
                    detailRow(label: "You put in", value: offer.youPutIn)
                    detailRow(label: "You may receive", value: offer.youMayReceive)
                    detailRow(label: "Main catch", value: offer.mainCatch)
                    detailRow(label: "Terms", value: offer.verificationLabel)
                }
                .padding(.top, 20)

                if !offer.verified {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current offer not verified")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BBTheme.ink)
                        Text("The operator remains on the map, but Bankroll Board will not rank or start this version until its terms are current.")
                            .font(.system(size: 12))
                            .foregroundStyle(BBTheme.inkMuted)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(BBTheme.gold.opacity(0.35), lineWidth: 1)
                    }
                    .padding(.top, 18)
                }

                BBPrimaryButton(title: "Review official source", isEnabled: true) {
                    onOpenOfficial(offer.officialURL)
                }
                .padding(.top, 22)

                BBFootnote(
                    text: "Must be 21+ and physically located in a state where the operator is licensed.",
                    symbol: "exclamationmark.shield"
                )
                .padding(.top, 16)
            }
            .padding(20)
        }
        .background(BBTheme.canvasDeep)
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 10))
                .kerning(0.5)
                .foregroundStyle(BBTheme.inkMuted)
                .frame(width: 92, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(rgb: 0xE5DDBC))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.4))
                .frame(height: 1)
        }
    }
}
