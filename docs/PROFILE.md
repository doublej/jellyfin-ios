# What AVPlayer plays: the device profile, measured

`Tests/ProbeTests/AVPlayerProbe.swift` (`just probe`) takes one file per kind in the library (container ·
video codec/profile/range · audio codec) and plays it four ways with AVPlayer: muted, in the app's process,
iPhone 17 simulator (iOS 26), against the real server on 2026-10-05. "OK" means a video frame came out and
the clock passed 1 s, and the time is how long that took. Raw results: `/tmp/jfios-probe.json` (not kept in the repo).

The library: 176 films and episodes, 175 MKV and 1 MP4. Video is H.264 (High/Main) or HEVC (Main, Main 10; SDR,
HDR10+, Dolby Vision). Audio is AAC, AC-3, E-AC-3, DTS or FLAC.

## Results

| File | Direct file | HLS, copy | HLS, audio → AAC | Download (MP4 remux, played from disk) |
|---|---|---|---|---|
| mkv · h264 High · aac | no (-11828 Cannot Open) | OK 4.8 s | n/a | OK 0.2 s |
| mkv · h264 High · ac3 | no | timeout* | OK 4.8 s | OK 0.2 s |
| mkv · h264 High · dts | no | no (-12848) | timeout* | OK 0.2 s |
| mkv · h264 High · eac3 | no | timeout* | timeout* | OK 0.2 s |
| mkv · h264 High · flac | no | OK 3.4 s | OK 3.3 s | OK 0.2 s |
| mkv · h264 Main · aac | no | OK 18.4 s* | n/a | OK 0.2 s |
| mkv · h264 Main · eac3 | no | OK 24.5 s* | OK 10.6 s | OK 0.2 s |
| mkv · hevc Main 10 · SDR · ac3 | no | OK 4.3 s | OK 6.3 s | OK 0.1 s (`hev1` → `hvc1`) |
| mkv · hevc Main 10 · SDR · eac3 | no | OK 16.3 s* | OK 3.3 s | OK 0.2 s (`hev1` → `hvc1`) |
| mkv · hevc Main · SDR · eac3 | no | timeout* | OK 9.2 s | OK 0.2 s (`hev1` → `hvc1`) |
| mkv · hevc Main 10 · HDR10+ · eac3 | no | no (-12927) | no (-12927) | OK 0.1 s (`hev1` → `hvc1`) |
| mkv · hevc Main 10 · Dolby Vision/HDR10 | no (timeout) | no (-12927) | no (-12927) | OK 0.2 s (`hev1` → `hvc1`) |
| mp4 · h264 High · aac (Asteroid City) | stalled in the probe; 1.8 s in the app | OK 14.1 s* | n/a | OK 0.1 s |

The download column is from a second run (`testDownloadedFilesPlay`) with the retag in place: as the server
writes them (`hev1`), the HEVC files gave no frame in 10 s.

\* Slow results and timeouts came while the server was busy (the probe asks for a new conversion every few
seconds, and the trickplay task was running earlier that day). In the app, an HLS remux of a film starts in
1.1–1.4 s once the server is idle (`JFIOS-TIMING play-started`).

Subtitles: an external SubRip file as `Stream.js` events gave 2,174 cues in 5.8 s. An embedded SubRip track as
HLS WebVTT appeared in 12.5 s. The same embedded track as `Stream.js` had nothing after 45 s (the server extracts
the whole track first, see docs/GAPS.md).

## What the profile says (`Kit/Profile/Capabilities.swift`)

- **Direct play:** only MP4/M4V/MOV with H.264 or HEVC and AAC, AC-3, E-AC-3, MP3, ALAC or FLAC. MKV never.
  Direct play also needs the file's default audio track and no image subtitle, the same rule as the web client.
- **HLS (fragmented MP4):** video H.264 and HEVC copied. Audio AAC, AC-3, E-AC-3, MP3, ALAC, FLAC copied.
  DTS isn't listed, so the server converts it to AAC: AVPlayer refused DTS copy with -12848.
- **HDR:** HEVC HDR10, HDR10+, HLG and Dolby Vision ranges stay in the profile. The simulator decodes both HDR
  samples from a file, but not through the server's HLS (-12927), so the fault is in that HLS stream, not in
  decoding. Not confirmed on a device yet.
- **Subtitles:** text formats (SubRip, WebVTT, ASS/SSA, …) are fetched as `Stream.js` events and drawn by the app,
  so offset and appearance work. Image formats (PGS, VobSub, DVB) are burned in by the server.
- **Downloads:** H.264 files are remuxed to MP4 (or converted at the chosen bitrate). HEVC files are remuxed in
  original quality and retagged `hev1` → `hvc1` on the device, because the server can't convert 10-bit HEVC to H.264.
