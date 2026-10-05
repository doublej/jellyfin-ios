import Darwin
import Foundation
import os

/// Launch-to-content timings for the quality bar, logged as `JFIOS-TIMING <event> <ms>`.
/// Read them with `xcrun simctl spawn booted log stream --predicate 'category == "timing"'`.
enum Timing {
    static let log = Logger(subsystem: "dev.jurrejan.jellyfin-ui", category: "timing")
    nonisolated(unsafe) private static var reported: Set<String> = []

    /// When the kernel started this process, so the time before `main` counts too.
    static let processStart: Date = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return Date() }
        let start = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: Double(start.tv_sec) + Double(start.tv_usec) / 1_000_000)
    }()

    /// Logs once per launch: milliseconds since the process started.
    static func mark(_ event: String, _ detail: String = "") {
        guard !reported.contains(event) else { return }
        reported.insert(event)
        let millis = Int(Date().timeIntervalSince(processStart) * 1000)
        log.notice("JFIOS-TIMING \(event, privacy: .public) \(millis, privacy: .public) ms \(detail, privacy: .public)")
    }

    /// Logs the span between two moments, for play-start splits.
    static func span(_ event: String, from start: Date, _ detail: String = "") {
        let millis = Int(Date().timeIntervalSince(start) * 1000)
        log.notice("JFIOS-TIMING \(event, privacy: .public) \(millis, privacy: .public) ms \(detail, privacy: .public)")
    }
}
