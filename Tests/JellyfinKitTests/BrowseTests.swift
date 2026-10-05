import Foundation
@testable import JellyfinKit
import Testing

struct BrowseTests {
    func value(_ query: Query, _ key: String) -> String? {
        query.first { $0.0 == key }?.1 ?? nil
    }

    @Test func defaultQuerySortsByName() {
        let query = ViewPrefs().query()
        #expect(value(query, "sortBy") == "SortName")
        #expect(value(query, "sortOrder") == "Ascending")
        #expect(value(query, "filters") == nil)
    }

    @Test func otherSortsBreakTiesByName() {
        var prefs = ViewPrefs()
        prefs.sortBy = "DateCreated"
        prefs.ascending = false
        #expect(value(prefs.query(), "sortBy") == "DateCreated,SortName")
        #expect(value(prefs.query(), "sortOrder") == "Descending")
    }

    @Test func filtersBecomeServerParameters() {
        var prefs = ViewPrefs()
        prefs.status = .unplayed
        prefs.genres = ["Drama", "Comedy"]
        prefs.years = [1999, 2001]
        prefs.quality = [.hd, .uhd, .bluray]
        let query = prefs.query(letter: "#")
        #expect(value(query, "filters") == "IsUnplayed")
        #expect(value(query, "genres") == "Drama|Comedy")
        #expect(value(query, "years") == "1999,2001")
        #expect(value(query, "isHd") == "true" && value(query, "is4K") == "true")
        #expect(value(query, "videoTypes") == "BluRay")
        #expect(value(query, "nameLessThan") == "A")
        #expect(prefs.activeFilterCount == 8)
    }

    @Test func sdAndHdCancelOut() {
        var prefs = ViewPrefs()
        prefs.quality = [.sd, .hd]
        #expect(value(prefs.query(), "isHd") == nil)
    }

    @Test func serverAddressCandidates() {
        #expect(Auth.candidateAddresses(" 192.168.1.20:8096/ ").map(\.absoluteString) == ["https://192.168.1.20:8096", "http://192.168.1.20:8096"])
        #expect(Auth.candidateAddresses("http://x:8096").count == 1)
        #expect(Auth.isSupported(version: "10.11.11") && !Auth.isSupported(version: "10.9.0"))
    }

    @Test func formatsLikeTheWebClient() {
        #expect(Format.clock(3723) == "1:02:03" && Format.clock(123) == "2:03")
        #expect(Format.duration(Ticks.from(seconds: 6720)) == "1h 52m")
        #expect(Format.episodeCode(season: 1, episode: 2) == "S1:E2")
    }

    @Test func blurHashAverageColour() throws {
        let color = try #require(BlurHash.averageColor("LEHV6nWB2yk8pyo0adR*.7kCMdnj"))
        #expect(abs(color.red - 151.0 / 255) < 0.001, "DC of HV6n is #979695")
        let pixels = try #require(BlurHash.pixels("LEHV6nWB2yk8pyo0adR*.7kCMdnj", width: 8, height: 8))
        #expect(pixels.count == 8 * 8 * 4)
    }
}
