# vivaldi-recent-tabs

Vivaldi mod that marks your recently used tabs, Opera-style: a fill gauge behind the favicon shows how long ago each tab was active.

With dozens of tabs open it's easy to lose the one you were just on. This mod draws a circle behind the favicon of the last 4 tabs you visited. The fill level shows the order:

| Tab                    | Fill |
|------------------------|------|
| previous (1 step back) | 100% |
| 2 steps back           | 75%  |
| 3 steps back           | 50%  |
| 4 steps back           | 25%  |

The active tab is left alone, since Vivaldi already highlights it. The color follows your theme's **Highlight** color, so it fits any theme.

Tested on Vivaldi 8.3 (Windows).

## Install

> **Vivaldi updates overwrite `window.html`.** Re-run the installer after each update.

All installers find the newest Vivaldi version, copy `recent-tabs.js` next to `window.html` and add a `<script>` tag to it. The original is backed up once as `window.html.bak`. Running an installer again is safe: it updates the script and doesn't add the tag twice. Restart Vivaldi afterwards.

### Windows

Double-click `install.cmd`, or:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

### macOS / Linux

```sh
sh install.sh
```

- **macOS:** looks in `/Applications` and `~/Applications` (Vivaldi and Vivaldi Snapshot).
- **Linux:** looks in `/opt/vivaldi`, `/opt/vivaldi-snapshot`, `/usr/share/vivaldi`, `/usr/lib/vivaldi`. Asks for `sudo` when the folder isn't writable.
- **Flatpak / Snap** installs are read-only and can't be modded this way.

### Custom location

If Vivaldi lives somewhere else, point the installer at its UI folder (the one containing `window.html`):

```sh
VIVALDI_UI_DIR=/path/to/resources/vivaldi sh install.sh
```

```powershell
$env:VIVALDI_UI_DIR = 'D:\Vivaldi\Application\8.3.4191.35\resources\vivaldi'; .\install.ps1
```

### Manual

1. Find Vivaldi's UI folder:
   - Windows: `%LOCALAPPDATA%\Vivaldi\Application\<version>\resources\vivaldi\`
   - macOS: `/Applications/Vivaldi.app/Contents/Frameworks/Vivaldi Framework.framework/Versions/<version>/Resources/vivaldi/`
   - Linux: `/opt/vivaldi/resources/vivaldi/`
2. Copy `recent-tabs.js` there.
3. Open `window.html` in that folder and add before `</body>`:
   ```html
   <script src="recent-tabs.js"></script>
   ```
4. Restart Vivaldi.

### Try it without installing

Open `vivaldi://inspect/#apps`, click **inspect** under `.../window.html`, go to **Console** and paste the contents of `recent-tabs.js`. It works in that window until restart. Pasting again replaces the previous copy, which makes it handy for tuning the settings.

## Settings

Edit the constants at the top of `recent-tabs.js`, then re-run the installer:

| Setting       | Default                            | Meaning                                                    |
|---------------|------------------------------------|------------------------------------------------------------|
| `COLOR`       | `var(--colorHighlightBg, #2070AE)` | Fill color. Any CSS color or Vivaldi theme variable.       |
| `ALPHA`       | `0.7`                              | Opacity of the filled part.                                |
| `EMPTY_ALPHA` | `0.2`                              | Opacity of the unfilled part (`0` = transparent).          |
| `SIZE`        | `33`                               | Circle diameter in px.                                     |
| `RING`        | `2`                                | Outline width in px (`0` = none).                          |
| `HEIGHTS`     | `[100, 75, 50, 25]`                | Fill level per position. Add or remove entries to change how many tabs are marked. |

## Uninstall

- Windows: `install.cmd /u` or `install.ps1 -Uninstall`
- macOS / Linux: `sh install.sh -u`

Then restart Vivaldi. Alternatively, restore `window.html.bak`.

## How it works

The script runs in Vivaldi's UI page, keeps a per-window history of `chrome.tabs.onActivated` events and injects one `<style>` element with rules targeting `#tab-<id>-favicon`. Because it only writes CSS, Vivaldi's re-renders of the tab bar don't wipe the marks.

## License

[MIT](LICENSE)
