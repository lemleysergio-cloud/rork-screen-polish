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

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        summary
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 8)

                        splitRow
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 20)

                        Text("STILL IN FLIGHT")
                            .bbEyebrowStyle()
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 28)

                        ForEach(Array(model.pendingSortedBySettlement.enumerated()), id: \.element.id) { index, transfer in
                            VStack(spacing: 0) {
                                if index > 0 {
                                    Rectangle()
                                        .fill(BBTheme.hairline.opacity(0.4))
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
                    .foregroundStyle(BBTheme.gold)
                }
            }
            .toolbarBackground(JourneyPalette.canvasDeep, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("home.pendingReview")
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(model.pendingTransfers.count) transfer\(model.pendingTransfers.count == 1 ? "" : "s") on the way")
                .font(BBTheme.headline(28))
                .foregroundStyle(BBTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(arrivalCaption)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
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
            .foregroundStyle(model.pendingNetCents < 0 ? Color(rgb: 0xE2928A) : BBTheme.positive)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 18)

            Text("Net change once it all settles")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
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
                tint: BBTheme.positive
            )
            splitTile(
                label: "LEAVING",
                cents: model.pendingOutflowCents,
                tint: Color(rgb: 0xE2928A)
            )
        }
    }

    private func splitTile(label: String, cents: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(BBTheme.inkMuted)
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
                .fill(Color.white.opacity(0.04))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
                }
        }
    }

    private var note: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.gold.opacity(0.9))
                .padding(.top, 1)

            Text("Counting pending money is a view preference. These transfers stay pending with your bank and keep showing in your activity until they settle.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
        }
    }

    // MARK: - Action bar

    /// The one decision this screen asks for, pinned where the thumb is.
    private var actionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.5))
                .frame(height: 1)

            VStack(spacing: 8) {
                Text(projectionCaption)
                    .font(.system(size: 11))
                    .foregroundStyle(BBTheme.inkMuted)
                    .monospacedDigit()

                if model.countsPendingInBalance {
                    Button {
                        model.setPendingCounted(false)
                        dismiss()
                    } label: {
                        Text("Stop counting pending")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(BBTheme.gold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(BBTheme.gold.opacity(0.45), lineWidth: 1)
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
                            .foregroundStyle(JourneyPalette.canvasDeep)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(BBTheme.gold)
                            }
                    }
                    .buttonStyle(BBPressStyle())
                }
            }
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(JourneyPalette.canvasDeep.opacity(0.94))
        }
    }

    private var projectionCaption: String {
        model.countsPendingInBalance
            ? "Settled only would show \(homeMoney(cents: model.settledCents, showsPlus: false))"
            : "Your balance would read \(homeMoney(cents: model.projectedCents, showsPlus: false))"
    }
}
