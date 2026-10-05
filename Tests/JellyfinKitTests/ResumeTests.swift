import Foundation
@testable import JellyfinKit
import Testing

struct ResumeTests {
    func item(position: Double, played: Bool = false, runtime: Double = 6000) -> Item {
        var item = Item(id: "x", type: "Movie")
        item.runTimeTicks = Ticks.from(seconds: runtime)
        item.userData = UserData(played: played, playbackPositionTicks: Ticks.from(seconds: position))
        return item
    }

    @Test func startsFromTheSavedPosition() {
        #expect(Resume.startSeconds(item(position: 1234)) == 1234)
    }

    @Test func anExplicitStartWins() {
        #expect(Resume.startSeconds(item(position: 1234), explicit: 0) == 0)
        #expect(Resume.startSeconds(item(position: 1234), explicit: 90) == 90)
    }

    @Test func aWatchedItemStartsAtZero() {
        #expect(Resume.startSeconds(item(position: 50, played: true)) == 0)
    }

    @Test func stoppingNearTheEndMarksWatched() {
        let data = Resume.userData(stoppedAt: 5500, runtime: 6000)
        #expect(data.played == true && data.playbackPositionTicks == 0)
    }

    @Test func stoppingEarlyLeavesNoResumePoint() {
        #expect(Resume.userData(stoppedAt: 120, runtime: 6000).playbackPositionTicks == 0)
    }

    @Test func stoppingMidwayKeepsThePosition() {
        let data = Resume.userData(stoppedAt: 3000, runtime: 6000)
        #expect(data.played == false && data.playbackPositionTicks == Ticks.from(seconds: 3000))
    }

    @Test func unmarkingRestoresTheResumePoint() {
        var memory = ResumeMemory()
        let watching = item(position: 1800)
        #expect(memory.toggle(watching, played: true) == 0)
        var marked = watching
        marked.userData = UserData(played: true, playbackPositionTicks: 0)
        #expect(memory.toggle(marked, played: false) == Ticks.from(seconds: 1800))
    }

    @Test func offlineProgressSyncsOnlyWhenNewer() {
        let now = Date()
        let pending = PendingProgress(itemId: "x", positionTicks: 10, played: false, updatedAt: now)
        var server = UserData()
        #expect(pending.shouldSync(over: server))
        server.lastPlayedDate = now.addingTimeInterval(-60)
        #expect(pending.shouldSync(over: server))
        server.lastPlayedDate = now.addingTimeInterval(60)
        #expect(!pending.shouldSync(over: server))
    }
}
