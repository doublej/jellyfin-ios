<script lang="ts">
  import { base } from '$app/paths'

  // One page, so the links are its sections. Keep GitHub last.
  const links = [
    { href: '#measured', label: 'Measured' },
    { href: '#features', label: 'Features' },
    { href: '#screens', label: 'Screens' },
    { href: 'https://github.com/doublej/jellyfin-ios', label: 'GitHub', external: true },
  ]
</script>

<nav aria-label="Main">
  <div class="nav-inner">
    <a href="{base}/" class="wordmark">
      <img src="{base}/icon.png" alt="" width="28" height="28" />Jellyfin UI
    </a>
    <div class="nav-links">
      {#each links as link}
        <a
          href={link.href}
          target={link.external ? '_blank' : undefined}
          rel={link.external ? 'noopener noreferrer' : undefined}
        >
          {link.label}
        </a>
      {/each}
    </div>
  </div>
</nav>

<style>
  /* Solid, no blur: DESIGN.md keeps surfaces flat */
  nav {
    position: sticky;
    top: 0;
    z-index: 100;
    background: var(--paper);
    border-bottom: 1px solid var(--rule);
  }

  .nav-inner {
    max-width: var(--container-max-width);
    margin: 0 auto;
    padding: 0 var(--container-padding);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    height: 56px;
  }

  .wordmark {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    font-size: 1rem;
    font-weight: 680;
    letter-spacing: -0.02em;
    color: var(--ink);
    text-decoration: none;
    white-space: nowrap;
  }

  .wordmark img { border-radius: 6px; }

  .nav-links {
    display: flex;
    align-items: center;
    gap: clamp(12px, 3vw, 28px);
  }

  .nav-links a {
    font-size: 0.9375rem;
    font-weight: 500;
    color: var(--ink-soft);
    text-decoration: none;
    padding: 6px 0;
    transition: color var(--ease);
  }

  .nav-links a:hover { color: var(--ink); }

  @media (max-width: 520px) {
    .nav-links a:not(:last-child):not(:first-child) { display: none; }
  }
</style>
