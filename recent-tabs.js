// vivaldi-recent-tabs — Opera-style recent tab indicator for Vivaldi.
// https://github.com/dmitrydvornichenko/vivaldi-recent-tabs
// MIT License
//
// Each recently used tab is filled from the bottom like a gauge:
// the more recently the tab was active, the higher the fill level.
(function () {
  // ---- Settings -------------------------------------------------------------
  // Fill color: theme highlight color by default; any CSS color works too, e.g. '#2070AE'
  const COLOR       = 'var(--colorHighlightBg, #2070AE)';
  const ALPHA       = 0.25;                // opacity of the filled part (0..1)
  const EMPTY_ALPHA = 0;                   // opacity of the unfilled part (0 = transparent)
  const RING_ALPHA  = 0.5;                 // opacity of the outline (0..1)
  const SOFT        = 10;                  // blur of the fill edge, % of tab height (0 = sharp)
  const RING        = 2;                   // outline width, px (0 = no outline)
  const COUNT       = 4;                   // how many recent tabs to mark
  // Fill levels, %: evenly spaced by default (COUNT = 4 gives 100, 75, 50, 25).
  // Set your own list to override, e.g. [100, 60, 30]; its length then replaces COUNT.
  const LEVELS      = null;
  // ---------------------------------------------------------------------------

  const HEIGHTS = Array.isArray(LEVELS) && LEVELS.length
    ? LEVELS
    : Array.from({ length: Math.max(1, COUNT) }, (_, i) => Math.round(100 * (COUNT - i) / COUNT));
  const DEPTH = HEIGHTS.length;
  const tint  = a => `color-mix(in srgb, ${COLOR} ${a * 100}%, transparent)`;

  function start() {
    if (!window.chrome || !chrome.tabs || !document.head) return setTimeout(start, 300);

    // Allow re-running (e.g. pasting into DevTools): drop previous copies.
    document.querySelectorAll('style#recent-tabs-glow').forEach(s => s.remove());
    const gen = window.__recentTabsGen = (window.__recentTabsGen || 0) + 1;

    const history = [];   // tab ids, most recent first; [0] is the active tab
    let myWindowId = null;
    const style = document.createElement('style');
    style.id = 'recent-tabs-glow';
    document.head.appendChild(style);

    // The id sits on .tab-wrapper, but the rounded shape is drawn by the .tab inside it.
    function radius(id) {
      const tab = document.querySelector(`#tab-${id} .tab`);
      return tab ? getComputedStyle(tab).borderRadius : '0px';
    }

    function render() {
      style.textContent = history.slice(1, DEPTH + 1).map((id, i) => {
        // A full tab is filled solid: a soft edge at 100% would fade out the top strip.
        const full = HEIGHTS[i] >= 100;
        const lo = full ? 100 : Math.max(HEIGHTS[i] - SOFT, 0);
        const hi = full ? 100 : Math.min(HEIGHTS[i] + SOFT, 100);
        return `
#tab-${id} { position: relative; }
#tab-${id}::after {
  content: ''; position: absolute; inset: 0;
  box-sizing: border-box; border-radius: ${radius(id)};
  border: ${RING}px solid ${tint(RING_ALPHA)};
  background: linear-gradient(to top, ${tint(ALPHA)} ${lo}%, ${tint(EMPTY_ALPHA)} ${hi}%);
  pointer-events: none; z-index: 5;
}`;
      }).join('\n');
    }

    function touch(id) {
      const i = history.indexOf(id);
      if (i !== -1) history.splice(i, 1);
      history.unshift(id);
      if (history.length > DEPTH + 1) history.length = DEPTH + 1;
      render();
    }

    chrome.windows.getCurrent(w => {
      myWindowId = w.id;
      chrome.tabs.query({ active: true, windowId: myWindowId }, t => t[0] && touch(t[0].id));
    });
    chrome.tabs.onActivated.addListener(({ tabId, windowId }) => {
      if (gen !== window.__recentTabsGen) return;
      if (windowId === myWindowId) touch(tabId);
    });
    chrome.tabs.onRemoved.addListener(id => {
      if (gen !== window.__recentTabsGen) return;
      const i = history.indexOf(id);
      if (i !== -1) { history.splice(i, 1); render(); }
    });
  }

  start();
})();
