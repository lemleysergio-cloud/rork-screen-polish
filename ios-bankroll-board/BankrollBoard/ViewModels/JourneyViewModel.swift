//
//  JourneyViewModel.swift
//  BankrollBoard
//

import Foundation
import Observation

/// Drives the Journey screen: region selection, orbit focus, die rolls, and trail filtering.
@Observable
final class JourneyViewModel {
    /// Currently browsed state code.
    private(set) var regionCode: String = "MI"

    /// Ordered offers for the current region.
    private(set) var offers: [JourneyOffer] = JourneyContent.offers(for: "MI")

    /// Index of the offer parked at the front of the orbit.
    private(set) var focusIndex: Int = 0

    /// Live drag offset in node steps while the user swipes the ring.
    var dragProgress: Double = 0

    /// Incremented to ask the die to tumble.
    private(set) var rollToken: Int = 0

    /// Face the die last landed on.
    private(set) var dieFace: Int = 5

    private(set) var filter: JourneyFilter = .all

    var selectedOfferID: String?
    var isRegionPickerPresented: Bool = false

    init() {
        focusIndex = offers.firstIndex { $0.state == .current } ?? 0
    }

    // MARK: - Derived

    var region: JourneyRegion { JourneyContent.region(regionCode) }

    var money: JourneyMoney { JourneyContent.money(for: regionCode) }

    var stamps: [JourneyStamp] {
        JourneyContent.stamps(
            completedOffers: money.completedAllRegions,
            netProfit: money.verifiedNetProfit
        )
    }

    var earnedStampCount: Int { stamps.filter(\.earned).count }

    /// Continuous orbit phase used to place nodes and sweep the ring.
    var orbitPhase: Double { Double(focusIndex) + dragProgress }

    var focusedOffer: JourneyOffer? {
        guard offers.indices.contains(focusIndex) else { return nil }
        return offers[focusIndex]
    }

    /// Offer whose sheet is open, if any.
    var selectedOffer: JourneyOffer? {
        guard let selectedOfferID else { return nil }
        return offers.first { $0.id == selectedOfferID }
    }

    var currentOffer: JourneyOffer? {
        offers.first { $0.state == .current }
    }

    /// Offers shown in the trail list for the active filter.
    var trailOffers: [JourneyOffer] {
        switch filter {
        case .best:
            offers.filter { $0.rank != nil && $0.verified }
        case .active:
            offers.filter(\.isActiveProgress)
        case .all:
            offers
        }
    }

    var trailCaption: String {
        switch filter {
        case .best:
            "\(trailOffers.count) ranked offers in \(region.name). Your pace, your path."
        case .active:
            "\(trailOffers.count) active offers across all states. Your pace, your path."
        case .all:
            "\(trailOffers.count) offers shown · \(offers.count) mapped. Your pace, your path."
        }
    }

    /// Short label under the orbit describing the focused node's position.
    var focusRankCaption: String {
        guard let focusedOffer else { return "No mapped offers" }
        guard let rank = focusedOffer.rank else { return "Additional offer · not ranked" }
        return "Best-offer rank · #\(rank) of \(offers.count)"
    }

    // MARK: - Intent

    func selectRegion(_ code: String) {
        guard code != regionCode else {
            isRegionPickerPresented = false
            return
        }
        regionCode = code
        offers = JourneyContent.offers(for: code)
        focusIndex = offers.firstIndex { $0.state == .current } ?? 0
        dragProgress = 0
        isRegionPickerPresented = false
        rollDie()
    }

    func select(filter newValue: JourneyFilter) {
        guard newValue != filter else { return }
        filter = newValue
    }

    /// Moves orbit focus by whole steps, clamped to the catalog.
    func moveFocus(by delta: Int) {
        guard !offers.isEmpty else { return }
        let target = min(max(focusIndex + delta, 0), offers.count - 1)
        guard target != focusIndex else { return }
        focusIndex = target
    }

    func focus(on offerID: String) {
        guard let index = offers.firstIndex(where: { $0.id == offerID }) else { return }
        if index == focusIndex {
            selectedOfferID = offerID
        } else {
            focusIndex = index
        }
    }

    /// Settles a finished drag onto the nearest node.
    func commitDrag() {
        let steps = Int(dragProgress.rounded())
        dragProgress = 0
        moveFocus(by: steps)
    }

    /// Clamps live drag so the ring cannot be swiped past either end.
    func clampedDrag(_ proposed: Double) -> Double {
        let lower = Double(-focusIndex) - 0.35
        let upper = Double(max(0, offers.count - 1 - focusIndex)) + 0.35
        return min(max(proposed, lower), upper)
    }

    func rollDie() {
        rollToken += 1
    }

    func dieLanded(on face: Int) {
        dieFace = face
    }
}
