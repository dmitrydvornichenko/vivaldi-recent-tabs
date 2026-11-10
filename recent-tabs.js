// vivaldi-recent-tabs — Opera-style recent tab indicator for Vivaldi.
// https://github.com/dmitrydvornichenko/vivaldi-recent-tabs
// MIT License
//
// A circle behind the favicon of each recently used tab is filled from the
// bottom: the more recently the tab was active, the higher the fill level.
(function () {
  // ---- Settings -------------------------------------------------------------
  // Fill color: theme highlight color by default; any CSS color works too, e.g. '#2070AE'
  const COLOR       = 'var(--colorHighlightBg, #2070AE)';
  const ALPHA       = 0.7;                 // opacity of the filled part (0..1)
  const EMPTY_ALPHA = 0.2;                 // opacity of the unfilled part (0 = transparent)
  const SIZE        = 33;                  // circle diameter, px (favicon is ~16px)
  const RING        = 2;                   // outline width, px (0 = no outline)
  const HEIGHTS     = [100, 75, 50, 25];   // fill level, %; one entry per highlighted tab
  // ---------------------------------------------------------------------------

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

    function render() {
      style.textContent = history.slice(1, DEPTH + 1).map((id, i) => `
#tab-${id}-favicon { position: relative; z-index: 0; overflow: visible !important; }
#tab-${id}-favicon::before {
  content: ''; position: absolute; left: 50%; top: 50%;
  width: ${SIZE}px; height: ${SIZE}px; transform: translate(-50%, -50%);
  box-sizing: border-box; border-radius: 50%;
  border: ${RING}px solid ${tint(ALPHA)};
  background: linear-gradient(to top, ${tint(ALPHA)} ${HEIGHTS[i]}%, ${tint(EMPTY_ALPHA)} ${HEIGHTS[i]}%);
  pointer-events: none; z-index: -1;
}`).join('\n');
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
