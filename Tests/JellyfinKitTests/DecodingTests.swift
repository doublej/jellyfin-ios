import Foundation
@testable import JellyfinKit
import Testing

struct DecodingTests {
    @Test func keepsDictionaryKeysAsSent() throws {
        let item = try JSONCoding.decoder.decode(Item.self, from: Data(#"{"Id":"a","ImageTags":{"Primary":"x"}}"#.utf8))
        #expect(item.imageTags?["Primary"] == "x")
    }

    @Test func readsSevenDigitFractions() {
        #expect(JSONCoding.parseDate("2026-10-04T21:57:41.5749749Z") != nil)
        #expect(JSONCoding.parseDate("2026-10-04T21:57:41Z") != nil)
    }

    @Test func decodesAFilmWithChaptersCastAndStreams() throws {
        let film = try Fixture.decode(Item.self, "movie")
        #expect(film.kind == .movie)
        #expect(film.name == "Asteroid City")
        #expect(film.chapters?.count == 20)
        #expect((film.people?.count ?? 0) > 10)
        let source = try #require(film.mediaSources?.first)
        #expect(source.container == "mp4")
        #expect(source.video?.codec == "h264")
        #expect(!source.audioTracks.isEmpty)
        #expect(film.backdropArt != nil && film.posterArt != nil)
    }

    @Test func decodesAnEpisodeWithTrickplay() throws {
        let episode = try Fixture.decode(Item.self, "episode")
        #expect(episode.kind == .episode)
        #expect(episode.seriesName == "Ted Lasso")
        let sourceId = try #require(episode.mediaSources?.first?.id)
        let info = try #require(Timeline.pickTrickplay(episode.trickplay?[sourceId]))
        #expect(info.width == 320 && info.tileWidth == 10 && info.thumbnailCount == 186)
        #expect(episode.mediaSources?.first?.subtitleTracks.first?.codec == "subrip")
    }

    @Test func decodesNextUpPage() throws {
        let page = try Fixture.decode(ItemsResult.self, "nextup")
        #expect(page.items?.isEmpty == false)
        #expect(page.items?.allSatisfy { $0.kind == .episode } == true)
    }

    @Test func encodesPascalCaseForTheServer() throws {
        let state = ReportState(itemId: "i", mediaSourceId: "s", playSessionId: "p", playMethod: .transcode,
                                position: 12.5, paused: false, muted: false, volume: 1, audio: 1, subtitle: nil)
        let json = try #require(String(data: JSONCoding.encoder.encode(state), encoding: .utf8))
        #expect(json.contains(#""PositionTicks":125000000"#))
        #expect(json.contains(#""SubtitleStreamIndex":-1"#))
        #expect(json.contains(#""PlayMethod":"Transcode""#))
    }
}
