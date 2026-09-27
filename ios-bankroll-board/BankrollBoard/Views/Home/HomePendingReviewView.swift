//
//  HomePendingReviewView.swift
//  BankrollBoard
//
//  Review money the bank has authorized but not settled, then decide whether
//  to count it in the balance and chart.
//

import SwiftUI

struct HomePendingReviewView: View {
    let model: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.homePalette) private var palette

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        summary
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 8)

                        splitRow
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 20)

                        Text("STILL IN FLIGHT")
                            .homeEyebrowStyle(palette)
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 28)

                        ForEach(Array(model.pendingSortedBySettlement.enumerated()), id: \.element.id) { index, transfer in
                            VStack(spacing: 0) {
                                if index > 0 {
                                    Rectangle()
                                        .fill(palette.hairline.opacity(0.4))
                                        .frame(height: 1)
                                }
                                HomeActivityRow(transfer: transfer)
                            }
                            .padding(.horizontal, BBTheme.screenMargin)
                        }

                        note
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 22)
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .presentationContentInteraction(.scrolls)
            }
            .safeAreaInset(edge: .bottom) { actionBar }
            .navigationTitle("Pending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(palette.accent)
                }
            }
            .toolbarBackground(palette.backgroundColors.first ?? .clear, for: .navigationBar)
        }
        .preferredColorScheme(palette.colorScheme)
        .accessibilityIdentifier("home.pendingReview")
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(model.pendingTransfers.count) transfer\(model.pendingTransfers.count == 1 ? "" : "s") on the way")
                .font(BBTheme.headline(28))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(arrivalCaption)
                .font(.system(size: 12))
                .foregroundStyle(palette.inkMuted)
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                let parts = homeBalanceParts(cents: model.pendingNetCents)
                Text(parts.dollars)
                    .font(BBTheme.money(40))
                Text(parts.cents)
                    .font(BBTheme.money(26))
                    .opacity(0.85)
            }
            .foregroundStyle(model.pendingNetCents < 0 ? palette.negative : palette.positive)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 18)

            Text("Net change once it all settles")
                .font(.system(size: 11))
                .foregroundStyle(palette.inkMuted)
                .padding(.top, 6)
        }
    }

    private var arrivalCaption: String {
        guard let last = model.lastExpectedSettlement else {
            return "Your bank hasn't given an arrival estimate yet."
        }
        return "Your bank expects everything to land by \(homeShortDate(last))."
    }

    /// Money in versus money out, so a small net figure doesn't hide big movement.
    private var splitRow: some View {
        HStack(spacing: 10) {
            splitTile(
                label: "ARRIVING",
                cents: model.pendingInflowCents,
                tint: palette.positive
            )
            splitTile(
                label: "LEAVING",
                cents: model.pendingOutflowCents,
                tint: palette.negative
            )
        }
    }

    private func splitTile(label: String, cents: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(palette.inkMuted)
            Text(homeMoney(cents: cents, showsPlus: false))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.hairline.opacity(0.7), lineWidth: 1)
                }
        }
    }

    private var note: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(palette.accent.opacity(0.9))
                .padding(.top, 1)

            Text("Counting pending money is a view preference. These transfers stay pending with your bank and keep showing in your activity until they settle.")
                .font(.system(size: 11))
                .foregroundStyle(palette.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.hairline.opacity(0.6), lineWidth: 1)
        }
    }

    // MARK: - Action bar

    /// The one decision this screen asks for, pinned where the thumb is.
    private var actionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(palette.hairline.opacity(0.5))
                .frame(height: 1)

            VStack(spacing: 8) {
                Text(projectionCaption)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.inkMuted)
                    .monospacedDigit()

                if model.countsPendingInBalance {
                    Button {
                        model.setPendingCounted(false)
                        dismiss()
                    } label: {
                        Text("Stop counting pending")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(palette.accent.opacity(0.45), lineWidth: 1)
                            }
                    }
                    .buttonStyle(BBPressStyle())
                } else {
                    Button {
                        model.setPendingCounted(true)
                        dismiss()
                    } label: {
                        Text("Count pending in my balance")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.onAccentFill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(palette.accentFill)
                            }
                    }
                    .buttonStyle(BBPressStyle())
                }
            }
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(palette.barFill)
        }
    }

    private var projectionCaption: String {
        model.countsPendingInBalance
            ? "Settled only would show \(homeMoney(cents: model.settledCents, showsPlus: false))"
            : "Your balance would read \(homeMoney(cents: model.projectedCents, showsPlus: false))"
    }
}
