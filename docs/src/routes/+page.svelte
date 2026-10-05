<!--
  One page: hero -> measured (stat tiles + Terminal demo) -> features -> screens -> build + docs.
  Facts come from the repo's TASKS.md, docs/GAPS.md and docs/PROFILE.md; keep them in step.
-->
<script lang="ts">
  import { base } from '$app/paths'
  import { obliterate } from 'orphan-obliterator'
  import { onMount } from 'svelte'
  import Terminal from '$lib/components/Terminal.svelte'

  type Mode = 'build' | 'install' | 'test'
  type Tone = 'hi' | 'dim' | 'ok' | 'err'
  type Line = string | { text: string; tone: Tone }

  const repo = 'https://github.com/doublej/jellyfin-ios'
  // The app lives on feature/v1 until it merges; switch to 'main' then.
  const ref = 'feature/v1'
  const doc = (path: string) => `${repo}/blob/${ref}/${path}`

  let mode = $state<Mode>('build')
  let copied = $state<string | null>(null)
  let step = $state(0)

  const commands: Record<Mode, string> = {
    build: `git clone -b ${ref} ${repo} && cd jellyfin-ios && just xcode`,
    install: 'just device-install',
    test: 'just app-test',
  }
  const modes = Object.keys(commands) as Mode[]

  const stats = [
    { label: 'Warm launch to Home', value: '365 ms', note: 'median on iPhone 17, 442 ms on iPad Pro 11"' },
    { label: 'Direct play start', value: '1.8 s', note: 'the one MP4 in the library' },
    { label: 'HLS start', value: '1.1–1.4 s', note: 'an MKV remuxed by the server' },
    { label: 'Drift on a switch', value: '< 0.05 s', note: 'audio 0.0001 s, quality 0.04 s' },
  ]

  const steps: { title: string; description: string; command: string; output: Line[] }[] = [
    {
      title: 'Launch',
      description: 'Relaunch the installed, signed-in app five times and read the time to Home content from its own log.',
      command: 'just launch-timing',
      output: [
        { text: '# JFIOS-TIMING home-content, ms since the process started', tone: 'dim' },
        { text: 'median   365 ms   iPhone 17', tone: 'hi' },
        'median   442 ms   iPad Pro 11"',
        { text: 'target   ≤ 1 s', tone: 'dim' },
      ],
    },
    {
      title: 'Probe',
      description: 'Play one file of every kind in the library four ways. The device profile the app sends the server is built from what really played.',
      command: 'just probe',
      output: [
        { text: '# 176 films and episodes: 175 MKV, 1 MP4', tone: 'dim' },
        { text: 'direct file   MKV          no  (-11828 Cannot Open)', tone: 'err' },
        'direct file   MP4          OK  1.8 s in the app',
        'HLS, copy     H.264, HEVC  OK  when the server is idle',
        { text: 'HLS, copy     DTS audio    no  (-12848), so DTS goes to AAC', tone: 'err' },
        'download      every kind   OK  0.1–0.2 s from disk',
        { text: '# results: docs/PROFILE.md', tone: 'dim' },
      ],
    },
    {
      title: 'Play',
      description: 'Direct play when AVPlayer can open the file, otherwise HLS from the server. A direct stream that stalls for 6 s falls back to HLS.',
      command: `xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "JFIOS-TIMING"'`,
      output: [
        { text: '# play-started, server idle', tone: 'dim' },
        { text: 'direct play   Asteroid City (MP4)   1.80 s', tone: 'hi' },
        { text: '              PlaybackInfo 51 ms, 4.3 MB header over the LAN', tone: 'dim' },
        { text: 'HLS remux     a film (MKV)          1.1–1.4 s', tone: 'hi' },
      ],
    },
    {
      title: 'Switch',
      description: 'Change audio, subtitles or quality mid-film. The player attaches the new stream at the same position.',
      command: 'just app-test',
      output: [
        { text: '# UI tests on the iPhone 17 simulator, real server', tone: 'dim' },
        'audio switch     drift 0.0001 s   restart 2.3 s',
        'quality switch   drift 0.04 s     restart 3.6 s',
        'text subtitle    no restart',
        { text: "resume point shows in the web client's Continue Watching", tone: 'ok' },
      ],
    },
  ]

  const features = [
    {
      title: 'Home and libraries like the web client',
      description: 'Continue Watching, Next Up and Recently Added under a full-bleed backdrop hero. Libraries sort, filter by status, genre, year, rating and quality, jump by letter, and remember grid or list.',
    },
    {
      title: 'Plays what the phone can play',
      description: 'Direct play when AVPlayer can open the file, HLS from the server when it can’t. The device profile comes from probing a real library, not from a spec sheet.',
    },
    {
      title: 'Switch without losing your place',
      description: 'Audio, subtitle and quality changes keep the position. Subtitle timing, trickplay thumbnails on the seek bar, skip intro when the server has segments, and an Up Next countdown.',
    },
    {
      title: 'Picture in Picture, AirPlay, lock screen',
      description: 'The player has Picture in Picture, an AirPlay route picker, and Now Playing info with lock-screen and Control Center controls.',
    },
    {
      title: 'Downloads that report back',
      description: 'Pick a quality, follow the progress and play the file from the device. The position you reach goes back to the server.',
    },
    {
      title: 'At home on iPad',
      description: 'A sidebar that folds into the tab bar, wider layouts, and hardware-keyboard shortcuts in the player with the same keys as the web client.',
    },
  ]

  const phoneShots = [
    { src: 'iphone-17-home', alt: 'Home on iPhone: a backdrop hero with the film’s logo art, Play and Details, and a Next up row', caption: 'Home' },
    { src: 'iphone-17-film', alt: 'A film page on iPhone with Play, watched, favourite and download buttons, the plot and credits', caption: 'Film' },
    { src: 'iphone-17-library', alt: 'The Films library on iPhone as a poster grid with an alphabet jump bar', caption: 'Library' },
    { src: 'iphone-17-season', alt: 'A season page on iPhone listing its episodes with stills', caption: 'Season' },
  ]

  const padShots = [
    { src: 'ipad-pro-11-film', alt: 'A film page on iPad with Resume, the cast row and the backdrop behind the page', caption: 'Film page on iPad' },
    { src: 'ipad-pro-11-player', alt: 'The player on iPad with skip buttons, the seek bar, AirPlay and Picture in Picture', caption: 'Player on iPad' },
  ]

  const docs = [
    { href: doc('README.md'), label: 'README', note: 'build, test and install on a device' },
    { href: doc('TASKS.md'), label: 'TASKS.md', note: 'the v1 checklist and the quality bar' },
    { href: doc('docs/PROFILE.md'), label: 'docs/PROFILE.md', note: 'what AVPlayer plays, measured against the library' },
    { href: doc('docs/GAPS.md'), label: 'docs/GAPS.md', note: 'where the server wins: MKV goes HLS, no intro segments, no H.264 from 10-bit HEVC' },
  ]

  onMount(() => {
    const instance = obliterate({
      selectors: ['p', '.tagline', '.description', '.feature-list dd', '.stat-note', '.doc-list span'],
      rules: { minLastLineWords: 3, maxProtectedChars: 40 },
    })
    return () => instance.destroy()
  })

  function copyCommand(key: string, text: string) {
    navigator.clipboard.writeText(text)
    copied = key
    setTimeout(() => (copied = null), 2000)
  }
</script>

<main>
  <section class="hero" aria-labelledby="hero-title">
    <div class="container hero-grid">
      <div class="hero-text">
        <img class="hero-icon" src="{base}/icon.png" alt="" width="96" height="96" />
        <h1 id="hero-title">Jellyfin UI</h1>
        <p class="tagline">A native iPhone and iPad client for your Jellyfin server.</p>
        <p class="lede">
          SwiftUI on iOS 26. It matches the jellyfin-ui web client and adds AVPlayer playback, Picture in Picture,
          AirPlay, lock-screen controls and downloads.
        </p>
        <div class="hero-install">
          <div class="mode-toggle" role="group" aria-label="Command to show">
            {#each modes as m}
              <button aria-pressed={mode === m} onclick={() => (mode = m)}>{m[0].toUpperCase() + m.slice(1)}</button>
            {/each}
          </div>
          <div class="command-box">
            <code><span class="t-prompt"></span>{commands[mode]}</code>
            <button class="copy-btn" onclick={() => copyCommand('hero', commands[mode])}>
              {copied === 'hero' ? 'Copied' : 'Copy'}
            </button>
          </div>
          <div class="hero-links">
            <a class="btn primary" href={repo} target="_blank" rel="noopener noreferrer">Source on GitHub</a>
            <a class="btn" href={doc('README.md')} target="_blank" rel="noopener noreferrer">Read the README</a>
          </div>
        </div>
      </div>
      <figure class="phone hero-phone">
        <img
          src="{base}/shots/iphone-17-home.webp"
          alt="Home on iPhone: a backdrop hero with the film’s logo art, Play and Details, and a Next up row"
          width="600"
          height="1304"
          fetchpriority="high"
        />
      </figure>
    </div>
  </section>

  <section id="measured" class="measured" aria-labelledby="measured-title">
    <div class="container">
      <h2 id="measured-title">Built against a real server</h2>
      <p class="section-lede">
        Measured on 5 October 2026 in the iPhone 17 simulator, playing a real home library of 176 films and
        episodes over the LAN.
      </p>
      <dl class="stats">
        {#each stats as s}
          <div>
            <dt>{s.label}</dt>
            <dd class="stat-value">{s.value}</dd>
            <dd class="stat-note">{s.note}</dd>
          </div>
        {/each}
      </dl>

      <div class="demo-grid">
        <div class="demo-steps">
          <h3>How each number was taken</h3>
          <ol class="step-list">
            {#each steps as s, i}
              <li>
                <button aria-pressed={step === i} onclick={() => (step = i)}>
                  <span class="step-num">{i + 1}</span>{s.title}
                </button>
              </li>
            {/each}
          </ol>
          <p class="description" aria-live="polite">{steps[step].description}</p>
        </div>
        {#key step}
          <Terminal title="~/jellyfin-ios">
            <div><span class="t-prompt"></span>{steps[step].command}</div>
            {#each steps[step].output as line}
              {#if typeof line === 'string'}
                <div>{line || ' '}</div>
              {:else}
                <div class="t-{line.tone}">{line.text}</div>
              {/if}
            {/each}
          </Terminal>
        {/key}
      </div>
    </div>
  </section>

  <section id="features" class="features" aria-labelledby="features-title">
    <div class="container features-grid">
      <h2 id="features-title">What it does</h2>
      <dl class="feature-list">
        {#each features as feature}
          <div>
            <dt>{feature.title}</dt>
            <dd>{feature.description}</dd>
          </div>
        {/each}
      </dl>
    </div>
  </section>

  <section id="screens" class="screens" aria-labelledby="screens-title">
    <div class="container">
      <h2 id="screens-title">On iPhone and iPad</h2>
      <div class="phone-row">
        {#each phoneShots as s}
          <figure class="phone">
            <img src="{base}/shots/{s.src}.webp" alt={s.alt} width="600" height="1304" loading="lazy" decoding="async" />
            <figcaption>{s.caption}</figcaption>
          </figure>
        {/each}
      </div>
      <div class="pad-row">
        {#each padShots as s}
          <figure class="pad">
            <img src="{base}/shots/{s.src}.webp" alt={s.alt} width="1000" height="1451" loading="lazy" decoding="async" />
            <figcaption>{s.caption}</figcaption>
          </figure>
        {/each}
      </div>
    </div>
  </section>

  <section class="cta" aria-labelledby="cta-title">
    <div class="container cta-inner">
      <div class="cta-action">
        <h2 id="cta-title">Build it yourself</h2>
        <div class="command-box">
          <code><span class="t-prompt"></span>{commands.build}</code>
          <button class="copy-btn" onclick={() => copyCommand('cta', commands.build)}>
            {copied === 'cta' ? 'Copied' : 'Copy'}
          </button>
        </div>
        <p>Needs Xcode 26, xcodegen, swiftlint and just. <code>just device-install</code> puts a Release build on a paired iPhone.</p>
      </div>
      <ul class="doc-list">
        {#each docs as d}
          <li>
            <a href={d.href} target="_blank" rel="noopener noreferrer">{d.label}</a>
            <span>{d.note}</span>
          </li>
        {/each}
      </ul>
    </div>
  </section>
</main>

<footer>
  <div class="container">
    <p>A personal project by <a href="https://github.com/doublej" target="_blank" rel="noopener noreferrer">doublej</a>. Not made by or affiliated with the Jellyfin project.</p>
  </div>
</footer>

<style>
  section { padding: var(--section-padding) 0; }

  h2 {
    font-size: clamp(1.75rem, 3.4vw, 2.5rem);
    margin-bottom: 16px;
  }

  .section-lede { color: var(--ink-soft); max-width: 60ch; margin-bottom: clamp(32px, 5vw, 56px); }

  /* Hero: the artwork's average colour as a soft glow, as on the app's own hero */
  .hero {
    padding: clamp(40px, 7vw, 96px) 0 clamp(48px, 7vw, 96px);
    background:
      radial-gradient(55% 75% at 78% 35%, var(--glow), transparent 70%),
      var(--paper);
  }

  .hero-grid {
    display: grid;
    grid-template-columns: minmax(0, 7fr) minmax(0, 4fr);
    gap: var(--grid-gap);
    align-items: center;
  }

  .hero-icon { display: block; border-radius: 22px; margin-bottom: 24px; }

  h1 {
    font-size: clamp(2.75rem, 7vw, 5.5rem);
    font-weight: 700;
    letter-spacing: -0.03em;
    line-height: 0.95;
    margin-bottom: 20px;
  }

  .tagline {
    font-size: clamp(1.3rem, 2.4vw, 1.75rem);
    font-weight: 500;
    line-height: 1.25;
    letter-spacing: -0.01em;
    max-width: 26ch;
    margin-bottom: 14px;
  }

  .lede { color: var(--ink-soft); max-width: 52ch; margin-bottom: 32px; }

  .hero-install { display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; max-width: 620px; }
  .hero-install > :not(.command-box) { justify-self: start; }
  .hero-links { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }

  .mode-toggle {
    display: inline-flex;
    background: var(--paper-tint);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    padding: 3px;
    gap: 2px;
  }

  .mode-toggle button {
    border: none;
    border-radius: 4px;
    background: transparent;
    color: var(--ink-soft);
    font: inherit;
    font-size: 0.875rem;
    font-weight: 500;
    padding: 5px 14px;
    cursor: pointer;
    transition: background var(--ease), color var(--ease);
  }

  .mode-toggle button:hover { color: var(--ink); }
  .mode-toggle button[aria-pressed='true'] { background: var(--surface-2); color: var(--ink); }

  .command-box {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    width: 100%;
    background: var(--term-bg);
    color: var(--term-text);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    padding: 8px 8px 8px 16px;
  }

  .command-box code {
    min-width: 0;
    font-size: 0.8125rem;
    overflow-x: auto;
    white-space: nowrap;
    padding: 4px 0;
  }

  .copy-btn {
    flex-shrink: 0;
    border: none;
    background: var(--surface-2);
    color: var(--ink);
    font: inherit;
    font-size: 0.8125rem;
    font-weight: 500;
    min-width: 5.5em;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    transition: background var(--ease);
  }

  .copy-btn:hover { background: var(--rule); }

  /* Device frames: sized before the image loads, so nothing shifts */
  .phone, .pad { margin: 0; }

  .phone img, .pad img {
    display: block;
    width: 100%;
    height: auto;
    background: var(--paper-tint);
    border: 1px solid var(--rule);
  }

  .phone img { border-radius: 13% / 6%; }
  .pad img { border-radius: 4.5% / 3.1%; }

  .hero-phone { max-width: 320px; justify-self: center; width: 100%; }

  figcaption { color: var(--ink-soft); font-size: 0.875rem; margin-top: 12px; text-align: center; }

  /* Measured: four stat tiles, then the Terminal demo */
  .measured { background: var(--paper); border-top: 1px solid var(--rule); }

  .stats {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 2px;
    border-radius: var(--radius);
    overflow: hidden;
    margin-bottom: clamp(48px, 7vw, 88px);
  }

  .stats > div { background: var(--paper-tint); padding: 22px 22px 24px; }

  .stats dt { color: var(--ink-soft); font-size: 0.9375rem; margin-bottom: 6px; }

  .stat-value {
    font-size: clamp(2rem, 3.6vw, 3rem);
    font-weight: 650;
    letter-spacing: -0.02em;
    line-height: 1.1;
    white-space: nowrap;
    margin-bottom: 8px;
  }

  .stat-note { color: var(--ink-faint); font-size: 0.875rem; }

  .demo-grid {
    display: grid;
    grid-template-columns: minmax(0, 4fr) minmax(0, 7fr);
    gap: var(--grid-gap);
    align-items: start;
  }

  .demo-steps h3 { font-size: 1.25rem; margin-bottom: 16px; }

  .step-list { list-style: none; display: grid; gap: 2px; margin-bottom: 16px; }

  .step-list button {
    display: flex;
    align-items: center;
    gap: 14px;
    width: 100%;
    border: none;
    background: none;
    color: var(--ink-faint);
    font: inherit;
    font-size: 1.0625rem;
    font-weight: 500;
    text-align: left;
    padding: 8px 0;
    cursor: pointer;
    transition: color var(--ease);
  }

  .step-list button:hover, .step-list button[aria-pressed='true'] { color: var(--ink); }

  .step-num {
    display: grid;
    place-items: center;
    width: 28px;
    height: 28px;
    flex-shrink: 0;
    border: 1px solid var(--rule);
    border-radius: 4px;
    font-size: 0.8125rem;
    font-weight: 600;
    transition: background var(--ease), color var(--ease);
  }

  .step-list button[aria-pressed='true'] .step-num { background: var(--ink); border-color: var(--ink); color: var(--paper); }

  .description { color: var(--ink-soft); max-width: 40ch; min-height: 4.7em; }

  /* Keep the page still while steps with different output lengths swap in */
  .demo-grid :global(.terminal-body) { min-height: 15em; }

  /* Features: a definition list, not cards */
  .features { border-top: 1px solid var(--rule); }

  .features-grid {
    display: grid;
    grid-template-columns: minmax(0, 4fr) minmax(0, 7fr);
    gap: var(--grid-gap);
  }

  .feature-list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: clamp(28px, 4vw, 44px) var(--grid-gap);
  }

  .feature-list dt { font-size: 1.125rem; font-weight: 650; letter-spacing: -0.01em; margin-bottom: 6px; }
  .feature-list dd { color: var(--ink-soft); }

  /* Screens */
  .screens { border-top: 1px solid var(--rule); }
  .screens h2 { margin-bottom: clamp(32px, 5vw, 56px); }

  .phone-row {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: clamp(16px, 3vw, 32px);
    margin-bottom: clamp(48px, 7vw, 88px);
  }

  .pad-row {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: clamp(16px, 3vw, 32px);
  }

  /* Build + docs: the raised surface closes the page */
  .cta { background: var(--paper-tint); border-top: 1px solid var(--rule); }

  .cta-inner {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: var(--grid-gap);
    align-items: start;
  }

  .cta-action { display: grid; grid-template-columns: minmax(0, 1fr); gap: 16px; }
  .cta-action h2 { margin-bottom: 0; }
  .cta-action p { color: var(--ink-soft); }
  .cta-action p code { font-size: 0.875em; color: var(--ink); }

  .doc-list { list-style: none; display: grid; gap: 18px; padding-top: 8px; }
  .doc-list a { font-weight: 600; }
  .doc-list span { display: block; color: var(--ink-soft); font-size: 0.9375rem; }

  footer { border-top: 1px solid var(--rule); padding: 28px 0 36px; color: var(--ink-faint); font-size: 0.875rem; }

  @media (max-width: 900px) {
    .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }

  @media (max-width: 860px) {
    .hero-grid, .demo-grid, .features-grid, .cta-inner { grid-template-columns: minmax(0, 1fr); }
    .hero-phone { max-width: 260px; }
    .description { min-height: 0; }

    /* Phones scroll sideways rather than shrinking to stamps */
    .phone-row {
      grid-template-columns: none;
      grid-auto-flow: column;
      grid-auto-columns: minmax(200px, 62%);
      overflow-x: auto;
      scroll-snap-type: x mandatory;
      padding-bottom: 8px;
    }

    .phone-row .phone { scroll-snap-align: start; }
  }

  @media (max-width: 560px) {
    .feature-list, .pad-row { grid-template-columns: minmax(0, 1fr); }
    .stat-value { white-space: normal; }
    .command-box { padding-left: 12px; }
    .command-box code { font-size: 0.75rem; }
  }
</style>
