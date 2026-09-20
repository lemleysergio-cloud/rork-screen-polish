//
//  HomeActivityRow.swift
//  BankrollBoard
//
//  Casino monogram and a single transfer row in Recent activity.
//

import SwiftUI
import UIKit

/// Operator logo when the image set is bundled, otherwise an initials monogram
/// on the operator's brand color. Every casino renders something either way.
struct HomeCasinoMark: View {
    let casinoId: String
    var size: CGFloat = 38

    private var casino: HomeCasino? { HomeCasino.lookup(casinoId) }

    private var hasBundledLogo: Bool {
        guard let name = casino?.assetName else { return false }
        return UIImage(named: name) != nil
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            .fill(brandColor.opacity(0.18))
            .overlay {
                if hasBundledLogo, let name = casino?.assetName {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(size * 0.14)
                        .allowsHitTesting(false)
                } else {
                    Text(casino?.initials ?? "··")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(brandColor)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                    .stroke(brandColor.opacity(0.35), lineWidth: 1)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var brandColor: Color {
        Color(rgb: casino?.brandColorHex ?? 0x9AAE9F)
    }
}

/// One transfer: operator, direction, settlement state, and signed amount.
struct HomeActivityRow: View {
    let transfer: HomeTransfer

    private var amountColor: Color {
        transfer.cents < 0 ? Color(rgb: 0xE2928A) : BBTheme.positive
    }

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            HomeCasinoMark(casinoId: transfer.casinoId)

            VStack(alignment: .leading, spacing: 4) {
                Text(transfer.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BBTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 6) {
                    Text(transfer.direction.flowLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)

                    if transfer.status == .pending {
                        HomePendingBadge(expectedDate: transfer.expectedDate)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(homeMoney(cents: transfer.cents))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(homeShortDate(transfer.date))
                    .font(.system(size: 10))
                    .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
            }
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [transfer.title, transfer.direction.flowLabel, homeMoney(cents: transfer.cents)]
        if transfer.status == .pending {
            if let expected = transfer.expectedDate {
                parts.append("Pending, expected \(homeShortDate(expected))")
            } else {
                parts.append("Pending")
            }
        }
        return parts.joined(separator: ", ")
    }
}

/// Amber "Pending" chip with the bank's estimated arrival date.
struct HomePendingBadge: View {
    let expectedDate: Date?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 8, weight: .semibold))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .kerning(0.3)
        }
        .foregroundStyle(BBTheme.gold)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(BBTheme.gold.opacity(0.1))
                .overlay { Capsule().stroke(BBTheme.gold.opacity(0.32), lineWidth: 1) }
        }
    }

    private var label: String {
        guard let expectedDate else { return "PENDING" }
        return "ARRIVES \(homeShortDate(expectedDate).uppercased())"
    }
}
