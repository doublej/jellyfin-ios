<script lang="ts">
  import '@fontsource-variable/instrument-sans'
  import '../lib/styles/global.css'
  import Nav from '$lib/components/Nav.svelte'
  let { children } = $props()
</script>

<Nav />
{@render children()}
