import Foundation
@testable import JellyfinKit
import Testing

/// The same cases as jellyfin-ui `src/lib/player/rules/rules.test.ts`.
struct PlayerRulesTests {
    @Test func keysMatchTheWebClient() {
        #expect(Keys.action(for: KeyInput(key: " ")) == .toggle)
        #expect(Keys.action(for: KeyInput(key: "K")) == .toggle)
        #expect(Keys.action(for: KeyInput(key: "j")) == .back)
        #expect(Keys.action(for: KeyInput(key: "l")) == .forward)
        #expect(Keys.action(for: KeyInput(key: "N", shift: true)) == .next)
        #expect(Keys.action(for: KeyInput(key: "p", shift: true)) == .previous)
        #expect(Keys.action(for: KeyInput(key: "4")) == .percent(40))
        #expect(Keys.action(for: KeyInput(key: "PageUp")) == .nextChapter)
        #expect(Keys.action(for: KeyInput(key: "g")) == .subtitleEarlier)
        #expect(Keys.action(for: KeyInput(key: "Escape")) == .escape)
    }

    @Test func arrowsOnlyWithoutFocusAndNeverWithModifiers() {
        #expect(Keys.action(for: KeyInput(key: "ArrowLeft")) == .back)
        #expect(Keys.action(for: KeyInput(key: "ArrowUp")) == .volumeUp)
        #expect(Keys.action(for: KeyInput(key: "ArrowLeft"), controlFocused: true) == nil)
        #expect(Keys.action(for: KeyInput(key: "k", command: true)) == nil)
        #expect(Keys.action(for: KeyInput(key: "x")) == nil)
    }

    @Test func trickplayTilePicksSheetAndCell() throws {
        let info = TrickplayInfo(width: 320, height: 180, tileWidth: 10, tileHeight: 10, thumbnailCount: 250, interval: 10_000)
        #expect(Timeline.trickplayTile(info, seconds: 0) == .init(sheet: 0, x: 0, y: 0, width: 320, height: 180))
        #expect(Timeline.trickplayTile(info, seconds: 125) == .init(sheet: 0, x: 640, y: 180, width: 320, height: 180))
        #expect(try #require(Timeline.trickplayTile(info, seconds: 1005)).sheet == 1)
        #expect(try #require(Timeline.trickplayTile(info, seconds: 99_999)).sheet == 2)
    }

    @Test func segmentsAndUpNext() {
        let intro = MediaSegment(type: "Intro", start: 10, end: 60)
        #expect(Timeline.activeSegment([intro], seconds: 30) == intro)
        #expect(Timeline.activeSegment([intro], seconds: 59.5) == nil)
        #expect(Timeline.activeSegment([MediaSegment(type: "Intro", start: 0, end: 2)], seconds: 1) == nil)
        #expect(Timeline.upNextAt(runtime: 500) == nil)
        #expect(Timeline.upNextAt(runtime: 3600) == 3560)
        #expect(Timeline.upNextAt(runtime: 1800) == 1770)
        #expect(Timeline.upNextAt(runtime: 3600, outroStart: 3400) == 3400)
    }

    @Test func chapterSteps() {
        let chapters = [0.0, 300, 600].map { Chapter(start: $0) }
        #expect(Timeline.nextChapterStart(chapters, seconds: 100) == 300)
        #expect(Timeline.nextChapterStart(chapters, seconds: 650) == nil)
        #expect(Timeline.previousChapterStart(chapters, seconds: 305) == 0)
        #expect(Timeline.previousChapterStart(chapters, seconds: 400) == 300)
        #expect(Timeline.chapterAt(chapters, seconds: 450) == 1)
    }

    @Test func cuesHonourTheOffset() {
        let events = [TrackEvent(start: 1, end: 3, text: "a"), TrackEvent(start: 2, end: 4, text: "b"), TrackEvent(start: 10, end: 12, text: "c")]
        #expect(Cues.active(events, time: 2.5, offset: 0).map(\.text) == ["a", "b"])
        #expect(Cues.active(events, time: 11, offset: 0).map(\.text) == ["c"])
        #expect(Cues.active(events, time: 11, offset: 2).isEmpty)
        #expect(Cues.active(events, time: 3.5, offset: 1).map(\.text) == ["a", "b"])
    }

    @Test func cueMarkupKeepsOnlyItalicAndBold() {
        let lines = Cues.parse(#"{\an8}<i>Hello</i> <font color="red">there</font>\NSecond <b>line</b>"#)
        #expect(lines.count == 2)
        #expect(lines[0] == [.init(text: "Hello", italic: true), .init(text: " "), .init(text: "there")])
        #expect(lines[1] == [.init(text: "Second "), .init(text: "line", bold: true)])
        #expect(Cues.parseOffset("+1,5s") == 1.5)
        #expect(Cues.parseOffset("-45") == -30)
        #expect(Cues.parseOffset("abc") == nil)
    }
}

struct DeliveryTests {
    func url(_ reasons: String) -> URL { URL(string: "http://s/videos/x/master.m3u8?VideoCodec=h264&TranscodeReasons=\(reasons)")! }

    @Test func readsTheServersReasons() {
        #expect(Delivery.of(.directPlay, url: url("")).kind == .direct)
        #expect(Delivery.of(.transcode, url: url("ContainerNotSupported")) == Delivery(kind: .remux, causes: [.container]))
        #expect(Delivery.of(.transcode, url: url("ContainerNotSupported,AudioCodecNotSupported")).kind == .audio)
        #expect(Delivery.of(.transcode, url: url("ContainerBitrateExceedsLimit")).kind == .video)
        #expect(Delivery.of(.transcode, url: url("SubtitleCodecNotSupported")).causes == [.subtitles])
    }
}
