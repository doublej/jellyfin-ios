# Gaps: where the server (or the test setup) wins over the brief

Each gap says what the brief asked, why it can't be done as asked, and what the app does instead.
"Unconfirmed" means I couldn't prove the cause; where I looked is listed.
Server facts were read from the API on 2026-10-05 (Jellyfin on mbp-15-server, 192.168.178.120:8096).

## Skip intro and skip outro have nothing to skip
`GET /MediaSegments/{id}` returns no segments for any item tried (for example the Ted Lasso pilot), because the
server has no segment provider. The app reads segments and shows Skip when they exist, but in this library it
never does. To fix it, a segment plugin (for example Intro Skipper) has to be installed on the server, and that's a server change.

## Trickplay thumbnails exist for 64 items, not all
64 films and episodes have trickplay sheets. The seek bar shows tiles for those and a plain time label for the rest.
The server's trickplay task made every API call slow (117 s queries) while it ran, so I stopped it during testing with JJ's OK.
Its daily 03:00 trigger is unchanged, so it picks up where it left off.

## No user tiles on the sign-in screen
`GET /Users/Public` returns `[]`: every user is hidden on this server. The sign-in screen draws tiles when there are any,
and otherwise offers name + password and Quick Connect.

## 175 of 176 files are MKV, so nearly everything plays as HLS
AVPlayer can't open Matroska (`-11828 Cannot Open`, measured for every MKV sample, see docs/PROFILE.md). Direct play
only applies to the one MP4 in the library (Asteroid City). Everything else is served as HLS, usually a remux
(video and audio copied, "Remux" badge in the player). In the simulator, an HLS remux starts in 1.1–1.4 s.

## Direct play of the one MP4 stalled once (unconfirmed cause)
During the probe run, AVPlayer never got past "evaluating buffering rate" for `/Videos/{id}/stream.mp4?static=true`.
Later, in the app, the same film started in 1.80 s (`PlayerTimings.testFilmStarts`). The server side looked
healthy throughout: range requests return 206 in 0.09 s, the `moov` atom is at the front, and the first 12 MB
play locally in 1.8 s. My guess is the server being busy (probe conversions, the trickplay task), but it isn't
confirmed. I couldn't isolate it on macOS because LuLu blocks freshly built command-line binaries from the LAN.
As a safety net, a direct stream that isn't ready after 6 s now counts as failed and falls back to HLS with a notice.

## The server can't encode H.264 from 10-bit HEVC
FFmpeg's `h264_videotoolbox` fails with `cannot create compression session: -12903` on 10-bit HEVC input. Software
fallback is off, HEVC encoding is off (`AllowHevcEncoding: false`) and tone mapping is off. As a result:
- Downloads of HEVC files keep the original video and come in original quality only.
- A quality cap below the file's bitrate should fail the same way for 10-bit HEVC over HLS: the player shows the
  error, and choosing the original quality again plays the file. (Unconfirmed: I only saw the failure on the
  download URL, in the server's `FFmpeg.Transcode-*.log` on mbp15.)
- HDR files can't be converted to SDR.
To fix it, turn on software fallback or HEVC encoding in the server's playback settings. That's JJ's call; I didn't change it.

## The server's MP4 remux tags HEVC as `hev1`
`/Videos/{id}/stream.mp4` with `videoCodec=hevc` writes fragmented MP4 tagged `hev1`, and AVPlayer on iOS won't
decode it: the probe got no frame in 10 s. The `hvcC` box already has the parameter sets, so after a download
finishes the app renames the sample entry to `hvc1` (`MP4.retagHEVC`). The same file then plays.

## HDR10+ and Dolby Vision don't play over the server's HLS in the simulator (device unconfirmed)
HLS remuxes of the HDR10+ and Dolby Vision samples fail with CoreMedia `-12927`, but the same files remuxed to MP4
and played from disk work (download probe). So the simulator can decode them, and the fault is in the HLS stream
the server makes for HDR. I haven't found out what it is. The profile still offers HDR. Downloads of these films play.
Not tested on a device yet.

## Starting partway into a conversion can take long the first time
Croupier (FLAC audio, converted for HLS) took 39.8 s to start at 10:00 the first time ("No response for media
file in 3.17 s" from AVPlayer while the server spun up). The three switches after it restarted in 2.2–3.6 s.
The iPad screen tour was playing at the same time, so the server was busy.

## Embedded text subtitles are slow the first time
The server extracts an embedded subtitle track from the whole MKV before `Stream.js` answers. One sample took
more than 45 s, while the same track as HLS WebVTT appeared in 12.5 s. External subtitle files answer at once
(Asteroid City: 2,174 cues in 5.8 s).

## Marking played clears the resume point
That's the server's rule. Un-marking within the same session puts the position back (`ResumeMemory`), the same as the web client.

## Test setup: LuLu
LuLu on the Mac blocks simulator apps until "Allow simulator apps" is on. JJ turned it on on 2026-10-05.
