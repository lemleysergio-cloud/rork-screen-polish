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

    /// Unbounded orbit cursor. It keeps counting past either end of the catalog so
    /// the ring can spin forever in one direction; `focusedOfferIndex` wraps it back
    /// onto a real offer.
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

    /// Catalog index of the offer parked at the front of the orbit.
    var focusedOfferIndex: Int { wrapped(focusIndex) }

    var focusedOffer: JourneyOffer? {
        guard offers.indices.contains(focusedOfferIndex) else { return nil }
        return offers[focusedOfferIndex]
    }

    /// Maps the unbounded orbit cursor onto a valid catalog index.
    func wrapped(_ value: Int) -> Int {
        guard !offers.isEmpty else { return 0 }
        let count = offers.count
        return ((value % count) + count) % count
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

    /// Moves orbit focus by whole steps. The ring is a closed loop, so there is no end to hit.
    func moveFocus(by delta: Int) {
        guard !offers.isEmpty, delta != 0 else { return }
        focusIndex += delta
    }

    func focus(on offerID: String) {
        guard let index = offers.firstIndex(where: { $0.id == offerID }) else { return }
        if index == focusedOfferIndex {
            selectedOfferID = offerID
            return
        }
        moveFocus(by: shortestStep(to: index))
    }

    /// Shortest signed number of steps around the loop from the focused offer to `index`.
    private func shortestStep(to index: Int) -> Int {
        let count = offers.count
        guard count > 0 else { return 0 }
        let forward = ((index - focusedOfferIndex) % count + count) % count
        return forward <= count / 2 ? forward : forward - count
    }

    /// Settles a finished drag onto the nearest node.
    func commitDrag() {
        let steps = Int(dragProgress.rounded())
        dragProgress = 0
        moveFocus(by: steps)
    }

    /// The orbit is a closed loop, so live drag passes straight through — the user
    /// can keep swiping in one direction and cycle around the full catalog.
    func clampedDrag(_ proposed: Double) -> Double {
        proposed
    }

    func rollDie() {
        rollToken += 1
    }

    func dieLanded(on face: Int) {
        dieFace = face
    }
}
